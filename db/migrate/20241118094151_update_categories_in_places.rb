class UpdateCategoriesInPlaces < ActiveRecord::Migration[7.1]
  def change
    add_column :places, :primary_categories, :string
    add_column :places, :alternate_categories, :string, array: true, default: []

    # Add indexes to the new columns
    add_index :places, :primary_categories
    add_index :places, :alternate_categories, using: :gin

    # Remove the old categories column
    remove_column :places, :categories, :jsonb
  end
end
