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
          WHERE p.addresses->0->>'postcode' IS NOT NULL
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

  task import_division: :environment do |_, args|
    file_path = ENV['file']

    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      exit
    end

    batch_size = 1000
    batch = []

    puts "Starting import from #{file_path}..."

    factory = RGeo::Geographic.spherical_factory(srid: 4326)

    CSV.foreach(file_path, headers: true) do |row|
      geometry = row['geometry']
      subtype = row['subtype'] # expect country
      division_type = row['type'] # expect division area
      division_class = row['class'] # expect land
      division_id = row['division_id']

      import_divisions(factory, geometry, subtype, division_type, division_class, division_id)
    end

    puts "Import completed!"
  end

  desc 'Export SearchUnit data to CSV'
  task :export_search_unit, [:country_code, :excluded_postcodes] => :environment do |_, args|
    require 'csv'

    raise ArgumentError, 'country_code is missing' if args[:country_code].blank?

    country_code = args[:country_code]
    excluded_postcodes = []
    excluded_postcodes = excluded_postcodes.split(',') if args[:excluded_postcodes].present?

    file_path = Rails.root.join('search_units.csv')

    CSV.open(file_path, 'wb') do |csv|
      # Write the header row
      csv << [
        'country_code',
        'postcode',
        'ne_lat',
        'ne_lng',
        'sw_lat',
        'sw_lng',
        'cp_lat',
        'cp_lng',
        'radius',
        'area_splitting_threshold',
        'place_types'
      ]

      # Query and write data rows
      # SearchUnit.find_each do |unit|
      SearchGrid.where.not(postcode: excluded_postcodes)
                .where(status: :finished, is_land: true).find_each do |unit|
        csv << [
          country_code,
          unit.postcode,
          unit.ne_lat,
          unit.ne_lng,
          unit.sw_lat,
          unit.sw_lng,
          unit.center_lat,
          unit.center_lng,
          unit.radius,
          unit.area_splitting_threshold,
          "#{unit.place_types.join(',')}"
        ]
      end
    end

    puts "Exported to #{file_path}"
  end
end

def find_reasonable_grids(ne_lat:, ne_lng:, sw_lat:, sw_lng:, splitting_threshold:, category:, max_places: 8, min_splitting_threshold: 0.1, parent_grid_id: nil)
  grid = []
  lat = sw_lat

  while lat < ne_lat - 0.0003
    lng = sw_lng
    while lng < ne_lng - 0.0003
      # Southwest corner of the square
      sw_corner = [lat, lng]

      # Calculate the northeast corner by moving north and east from the southwest corner
      ne_corner = Geocoder::Calculations.endpoint(
        Geocoder::Calculations.endpoint(sw_corner, 0, splitting_threshold),
        90,
        splitting_threshold
      )

      # Ensure the northeast corner is within the area bounds
      ne_corner[0] = ne_lat if ne_corner[0] >= ne_lat - 0.0003
      ne_corner[1] = ne_lng if ne_corner[1] >= ne_lng - 0.0003

      # Add the square's corners to the grid
      southwest = sw_corner
      northeast = ne_corner

      cp_lat, cp_lng = Geocoder::Calculations.geographic_center([southwest, northeast])
      radius = ((Geocoder::Calculations.distance_between(southwest, northeast) / 2) * 1000).round(2) # meters

      place_results = get_place_results(lng, lat, ne_corner[1], ne_corner[0], category)
      # nearest_place = nearest_place(cp_lat, cp_lng) # comment out for perf

      grid = SearchGrid.create!(
        sw_lat: sw_corner[0],
        sw_lng: sw_corner[1],
        ne_lat: ne_corner[0],
        ne_lng: ne_corner[1],
        center_lat: cp_lat,
        center_lng: cp_lng,
        radius:,
        status: :finished,
        area_splitting_threshold: splitting_threshold,
        parent_grid_id:,
        place_results:,
        place_types: google_category(category),
        # postcode: nearest_place&.addresses[0]['postcode']
      )

      if place_results >= max_places && splitting_threshold > min_splitting_threshold
        grid.becoming_parent!
        find_reasonable_grids(ne_lat: ne_corner[0], ne_lng: ne_corner[1], sw_lat: sw_corner[0], sw_lng: sw_corner[1], category:, splitting_threshold: splitting_threshold / 2, parent_grid_id: grid.id)
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
  @google_categories ||= {}

  return @google_categories[category] unless @google_categories[category].nil?

  if category.blank?
    @google_categories[category] = []
  else
    @google_categories[category] = Place::CATEGORY_MAPPING[category]['google']
  end

  @google_categories[category]
end

def overture_category(category)
  @overture_category ||= {}

  return @overture_category[category] unless @overture_category[category].nil?

  if category.blank?
    @overture_category[category] = []
  else
    @overture_category[category] = Place::CATEGORY_MAPPING[category]['overture']
  end

  @overture_category[category]
end

def get_place_results(sw_lng, sw_lat, ne_lng, ne_lat, category)
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

def import_divisions(factory, geometry, subtype, division_type, division_class, division_id)
  postgis_geometry = RGeo::WKRep::WKTParser.new(factory, support_ewkt: true).parse(geometry)
  Division.create!(
    subtype: subtype,
    division_type: division_type,
    division_class: division_class,
    division_id: division_id,
    geometries: postgis_geometry
  )
end
