class AddIsLandToSearchGrid < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :search_grids, :is_land, :boolean, if_not_exists: true
  end
end
