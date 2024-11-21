# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_11_18_184214) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "cube"
  enable_extension "earthdistance"
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "places", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "name"
    t.jsonb "names"
    t.float "confidence"
    t.jsonb "websites"
    t.jsonb "socials"
    t.string "emails", default: [], array: true
    t.string "phones", default: [], array: true
    t.string "brand"
    t.jsonb "addresses"
    t.jsonb "sources"
    t.decimal "longitude", precision: 10, scale: 6
    t.decimal "latitude", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "primary_categories"
    t.string "alternate_categories", default: [], array: true
    t.index ["alternate_categories"], name: "index_places_on_alternate_categories", using: :gin
    t.index ["external_id"], name: "index_places_on_external_id", unique: true
    t.index ["primary_categories"], name: "index_places_on_primary_categories"
  end

  create_table "search_grids", force: :cascade do |t|
    t.decimal "sw_lat", precision: 10, scale: 6, null: false
    t.decimal "sw_lng", precision: 10, scale: 6, null: false
    t.decimal "ne_lat", precision: 10, scale: 6, null: false
    t.decimal "ne_lng", precision: 10, scale: 6, null: false
    t.decimal "center_lat", precision: 10, scale: 6, null: false
    t.decimal "center_lng", precision: 10, scale: 6, null: false
    t.integer "radius", null: false
    t.string "place_types", default: [], array: true
    t.string "hex_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["place_types"], name: "index_search_grids_on_place_types", using: :gin
  end

  create_table "spatial_ref_sys", primary_key: "srid", id: :integer, default: nil, force: :cascade do |t|
    t.string "auth_name", limit: 256
    t.integer "auth_srid"
    t.string "srtext", limit: 2048
    t.string "proj4text", limit: 2048
    t.check_constraint "srid > 0 AND srid <= 998999", name: "spatial_ref_sys_srid_check"
  end

end
