# frozen_string_literal: true
require 'csv'

namespace :places do
  task import: :environment do |_, args|
    file_path = ENV['file']

    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      exit
    end

    batch_size = 1000
    batch = []

    puts "Starting import from #{file_path}..."

    CSV.foreach(file_path, headers: true) do |row|
      batch << {
        external_id: row['id'],
        name: row['name'],
        names: JSON.parse(row['names'] || '{}'),
        primary_categories: row['primary_categories'],
        alternate_categories: row['alternate_categories'] ? row['alternate_categories'].split(',') : [],
        confidence: row['confidence'],
        websites: JSON.parse(row['websites'] || '[]'),
        socials: JSON.parse(row['socials'] || '[]'),
        emails: row['emails'] ? row['emails'].split(',') : [],
        phones: row['phones'] ? row['phones'].split(',') : [],
        brand: row['brand'],
        addresses: JSON.parse(row['addresses'] || '[]'),
        sources: JSON.parse(row['sources'] || '[]'),
        geopoint: row['geometry'],
        longitude: row['longitude'],
        latitude: row['latitude'],
        created_at: Time.now,
        updated_at: Time.now
      }

      if batch.size >= batch_size
        Place.insert_all(batch)
        batch.clear
        puts "Inserted #{batch_size} records..."
      end
    end

    # Insert any remaining records
    Place.insert_all(batch) unless batch.empty?
    puts "Import completed!"
  end

  task :build_grids, [:ne_lat, :ne_lng, :sw_lat, :sw_lng, :splitting_threshold] => :environment do |t, args|
    ne_lat = args[:ne_lat].to_f
    ne_lng = args[:ne_lng].to_f
    sw_lat = args[:sw_lat].to_f
    sw_lng = args[:sw_lng].to_f
    splitting_threshold = args[:splitting_threshold].to_f

    find_reasonable_grids(ne_lat:, ne_lng:, sw_lat:, sw_lng:, splitting_threshold:)

    puts "Build grids completed!"
  end
end

def find_reasonable_grids(ne_lat:, ne_lng:, sw_lat:, sw_lng:, splitting_threshold:, max_places: 20, min_splitting_threshold: 0.15, parent_grid_id: nil)
  grid = []
  lat = sw_lat

  while lat < ne_lat
    lng = sw_lng
    while lng < ne_lng
      # Southwest corner of the square
      sw_corner = [lat, lng]

      # Calculate the northeast corner by moving north and east from the southwest corner
      ne_corner = Geocoder::Calculations.endpoint(
        Geocoder::Calculations.endpoint(sw_corner, 0, splitting_threshold),
        90,
        splitting_threshold
      )

      # Ensure the northeast corner is within the area bounds
      ne_corner[0] = ne_lat if ne_corner[0] > ne_lat
      ne_corner[1] = ne_lng if ne_corner[1] > ne_lng

      # Add the square's corners to the grid
      southwest = sw_corner
      northeast = ne_corner

      cp_lat, cp_lng = Geocoder::Calculations.geographic_center([southwest, northeast])
      radius = Geocoder::Calculations.distance_between(southwest, northeast) / 2

      place_results = get_place_results(lng, lat, ne_corner[1], ne_corner[0])

      grid = SearchGrid.create!(
        sw_lat: lat,
        sw_lng: lng,
        ne_lat: ne_corner[0],
        ne_lng: ne_corner[1],
        center_lat: cp_lat,
        center_lng: cp_lng,
        radius: radius * 1000, # to meters
        status: :finished,
        area_splitting_threshold: splitting_threshold,
        parent_grid_id:,
        place_results:
      )

      if place_results >= max_places && splitting_threshold > min_splitting_threshold
        grid.becoming_parent!
        find_reasonable_grids(ne_lat: ne_corner[0], ne_lng: ne_corner[1], sw_lat: lat, sw_lng: lng, splitting_threshold: splitting_threshold / 2, parent_grid_id: grid.id)
      end

      # Move to the next square in the east direction
      lng = ne_corner[1]
    end

    # Move to the next row in the north direction
    lat = Geocoder::Calculations.endpoint([lat, sw_lng], 0, splitting_threshold)[0]
  end

  puts "Layer completed, splitting_threshold: #{splitting_threshold}"
end

def get_place_results(sw_lng, sw_lat, ne_lng, ne_lat)
  # TODO: query with specific `place_types`

  count = Place.where(
    "ST_MakeEnvelope(?, ?, ?, ?, 4326) && geopoint",
    sw_lng, sw_lat, ne_lng, ne_lat
  ).count

  count
end
