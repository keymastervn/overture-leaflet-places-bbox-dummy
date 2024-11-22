class AddSearchGridStatusAndResultAndAreaSplittingThreshold < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :search_grids, :status, :string, if_not_exists: true
    add_column :search_grids, :area_splitting_threshold, :float, if_not_exists: true
    add_column :search_grids, :parent_grid_id, :integer, if_not_exists: true
    add_column :search_grids, :place_results, :integer, if_not_exists: true
    add_column :search_grids, :postcode, :string, if_not_exists: true

    add_index :search_grids, :status, algorithm: :concurrently, if_not_exists: true
    add_index :search_grids, :parent_grid_id, algorithm: :concurrently, if_not_exists: true
    add_index :search_grids, :postcode, algorithm: :concurrently, if_not_exists: true
  end
end
