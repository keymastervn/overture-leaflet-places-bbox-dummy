class CreatePlaces < ActiveRecord::Migration[7.1]
  def change
    create_table :places do |t|
      t.string :external_id, null: false, index: { unique: true }
      t.string :name
      t.jsonb :names
      t.jsonb :categories
      t.float :confidence
      t.jsonb :websites
      t.jsonb :socials
      t.string :emails, array: true, default: []
      t.string :phones, array: true, default: []
      t.string :brand
      t.jsonb :addresses
      t.jsonb :sources
      t.decimal :longitude, precision: 10, scale: 6
      t.decimal :latitude, precision: 10, scale: 6

      t.timestamps
    end
  end
end
