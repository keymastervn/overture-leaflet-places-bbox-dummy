class TempDropIndexForPerf < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_index :search_grids, :place_types, if_exists: true
    remove_index :search_grids, :status, algorithm: :concurrently, if_exists: true
    remove_index :search_grids, :parent_grid_id, algorithm: :concurrently, if_exists: true
    remove_index :search_grids, :postcode, algorithm: :concurrently, if_exists: true
  end

  def down
    add_index :search_grids, :place_types, using: :gin, if_not_exists: true
    add_index :search_grids, :status, algorithm: :concurrently, if_not_exists: true
    add_index :search_grids, :parent_grid_id, algorithm: :concurrently, if_not_exists: true
    add_index :search_grids, :postcode, algorithm: :concurrently, if_not_exists: true
  end
end
