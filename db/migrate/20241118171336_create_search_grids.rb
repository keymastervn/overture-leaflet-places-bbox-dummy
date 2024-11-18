class CreateSearchGrids < ActiveRecord::Migration[7.1]
  def change
    create_table :search_grids do |t|
      t.decimal :sw_lat, precision: 10, scale: 6, null: false
      t.decimal :sw_lng, precision: 10, scale: 6, null: false
      t.decimal :ne_lat, precision: 10, scale: 6, null: false
      t.decimal :ne_lng, precision: 10, scale: 6, null: false
      t.decimal :center_lat, precision: 10, scale: 6, null: false
      t.decimal :center_lng, precision: 10, scale: 6, null: false
      t.integer :radius, null: false
      t.string :place_types, array: true, default: []
      t.string :hex_color

      t.timestamps
    end

    add_index :search_grids, :place_types, using: :gin
  end
end
