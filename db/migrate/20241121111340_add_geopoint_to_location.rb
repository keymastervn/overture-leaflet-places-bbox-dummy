class AddGeopointToLocation < ActiveRecord::Migration[7.1]
  def change
    add_column :places, :geopoint, :geography, limit: { srid: 4326, type: "point" }

    # Adding an index on the geography column
    add_index :places, :geopoint, using: :gist
  end
end
