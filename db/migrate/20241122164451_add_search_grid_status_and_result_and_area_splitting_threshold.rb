class AddSearchGridStatusAndResultAndAreaSplittingThreshold < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :search_grids, :status, :string
    add_column :search_grids, :area_splitting_threshold, :float
    add_column :search_grids, :parent_grid_id, :uuid
    add_column :search_grids, :place_results, :integer
    add_column :search_grids, :postcode, :string

    add_index :search_grids, :status, algorithm: :concurrently
    add_index :search_grids, :parent_grid_id, algorithm: :concurrently
    add_index :search_grids, :postcode, algorithm: :concurrently
  end
end
