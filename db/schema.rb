# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100408120352) do

  create_table "problems", :force => true do |t|
    t.text     "subject"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "reporter_id"
  end

  create_table "stops", :force => true do |t|
    t.string   "atco_code"
    t.string   "naptan_code"
    t.string   "plate_code"
    t.text     "common_name"
    t.string   "common_name_lang"
    t.text     "short_common_name"
    t.string   "short_common_name_lang"
    t.text     "landmark"
    t.string   "landmark_lang"
    t.text     "street"
    t.string   "street_lang"
    t.text     "crossing"
    t.string   "crossing_lang"
    t.text     "indicator"
    t.string   "indicator_lang"
    t.string   "bearing"
    t.string   "nptg_locality_code"
    t.string   "locality_name"
    t.string   "parent_locality_name"
    t.string   "grand_parent_locality_name"
    t.string   "town"
    t.string   "town_lang"
    t.string   "suburb"
    t.string   "suburb_lang"
    t.boolean  "locality_centre"
    t.string   "grid_type"
    t.float    "easting"
    t.float    "northing"
    t.float    "lon"
    t.float    "lat"
    t.string   "stop_type"
    t.string   "bus_stop_type"
    t.string   "administrative_area_code"
    t.datetime "creation_datetime"
    t.datetime "modification_datetime"
    t.integer  "revision_number"
    t.string   "modification"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "problems", "users", :name => "problems_reporter_id_fk", :column => "reporter_id", :dependent => :nullify

end
