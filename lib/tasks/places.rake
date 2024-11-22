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
end
