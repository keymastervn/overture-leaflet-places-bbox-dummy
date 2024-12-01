class AddIndiceToSearchGrid < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :search_grids, :place_types, using: :gin, if_not_exists: true
    add_index :search_grids, :status, algorithm: :concurrently, if_not_exists: true
    add_index :search_grids, :parent_grid_id, algorithm: :concurrently, if_not_exists: true
    add_index :search_grids, :postcode, algorithm: :concurrently, if_not_exists: true
    add_index :search_grids, [:center_lng, :center_lat], algorithm: :concurrently, if_not_exists: true
  end
end
