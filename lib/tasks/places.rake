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

  task :build_grids, [:ne_lat, :ne_lng, :sw_lat, :sw_lng, :splitting_threshold, :category] => :environment do |t, args|
    ne_lat = args[:ne_lat].to_f
    ne_lng = args[:ne_lng].to_f
    sw_lat = args[:sw_lat].to_f
    sw_lng = args[:sw_lng].to_f
    splitting_threshold = args[:splitting_threshold].to_f
    category = args[:category]

    find_reasonable_grids(ne_lat:, ne_lng:, sw_lat:, sw_lng:, splitting_threshold:, category:)

    puts "Build grids completed!"
  end

  task populate_postcodes: :environment do |_, args|
    puts "Populate postcodes based on the nearest to center of inner places"

    ActiveRecord::Base.connection.execute <<~SQL
      WITH nearest_places AS (
        SELECT
          sg.id AS grid_id,
          COALESCE(p.addresses->0->>'postcode', 'UNKNOWN') AS nearest_postcode
        FROM search_grids sg
        CROSS JOIN LATERAL (
          SELECT p.addresses
          FROM places p
          ORDER BY p.geopoint <-> ST_SetSRID(ST_MakePoint(sg.center_lng, sg.center_lat), 4326)
          LIMIT 1
        ) AS p
      )
      UPDATE search_grids
      SET postcode = np.nearest_postcode
      FROM nearest_places np
      WHERE search_grids.id = np.grid_id;
    SQL

    puts "Build grids completed!"
  end
end

def find_reasonable_grids(ne_lat:, ne_lng:, sw_lat:, sw_lng:, splitting_threshold:, category:, max_places: 16, min_splitting_threshold: 0.1, parent_grid_id: nil)
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
      # nearest_place = nearest_place(cp_lat, cp_lng) # comment out for perf

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
        place_results:,
        place_types: google_category(category),
        # postcode: nearest_place&.addresses[0]['postcode']
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

def google_category(category)
  return @google_categories if defined? @google_categories

  if category.blank?
    @google_categories = []
  else
    @google_categories = Place::CATEGORY_MAPPING[category]['google']
  end
end

def overture_category(category)
  return @overture_category if defined? @overture_category

  if category.blank?
    @overture_category = []
  else
    @overture_category = Place::CATEGORY_MAPPING[category]['overture']
  end
end

def get_place_results(sw_lng, sw_lat, ne_lng, ne_lat)
  if overture_category(category).blank?
    count = Place.where(
      "ST_MakeEnvelope(?, ?, ?, ?, 4326) && geopoint",
      sw_lng, sw_lat, ne_lng, ne_lat
    ).count
  else
    count = Place.where(
      "ST_MakeEnvelope(?, ?, ?, ?, 4326) && geopoint",
      sw_lng, sw_lat, ne_lng, ne_lat
    ).where(primary_categories: overture_category(category)).count
  end

  count
end

def nearest_place(center_lat, center_lng)
  sql = <<-SQL
    SELECT *
    FROM places
    ORDER BY ST_Distance(
      geopoint,
      ST_SetSRID(ST_MakePoint(?, ?), 4326)
    )
    LIMIT 1;
  SQL

  Place.find_by_sql([sql, center_lng, center_lat]).first
end

