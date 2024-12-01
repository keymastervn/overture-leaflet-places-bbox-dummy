class RecreateSearchGrid < ActiveRecord::Migration[7.1]
  def up
    drop_table :search_grids, if_exists: true

    create_table :search_grids, id: :uuid do |t|
      t.decimal :sw_lat, precision: 10, scale: 6, null: false
      t.decimal :sw_lng, precision: 10, scale: 6, null: false
      t.decimal :ne_lat, precision: 10, scale: 6, null: false
      t.decimal :ne_lng, precision: 10, scale: 6, null: false
      t.decimal :center_lat, precision: 10, scale: 6, null: false
      t.decimal :center_lng, precision: 10, scale: 6, null: false
      t.integer :radius, null: false
      t.string :place_types, array: true, default: []
      t.string :hex_color

      t.string :status
      t.float :area_splitting_threshold
      t.uuid :parent_grid_id
      t.integer :place_results
      t.string :postcode

      t.timestamps
    end
  end

  def down
    # nothing
  end
end
