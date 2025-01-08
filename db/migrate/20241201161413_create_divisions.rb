class CreateDivisions < ActiveRecord::Migration[7.1]
  def change
    create_table :divisions do |t|
      t.string :subtype, null: false
      t.string :division_type, null: false
      t.string :division_class, null: false
      t.string :division_id
      t.geometry :geometries, geographic: true, null: false

      t.timestamps
    end

    # Add GIST index for spatial queries
    add_index :divisions, :geometries, using: :gist
  end
end
