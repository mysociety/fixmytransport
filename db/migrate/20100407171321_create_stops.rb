class CreateStops < ActiveRecord::Migration
  def self.up
    create_table :stops do |t|
      t.string :atco_code
      t.string :naptan_code
      t.string :plate_code
      t.text :common_name
      t.string :common_name_lang
      t.text :short_common_name
      t.string :short_common_name_lang
      t.text :landmark
      t.string :landmark_lang
      t.text :street
      t.string :street_lang
      t.text :crossing
      t.string :crossing_lang
      t.text :indicator
      t.string :indicator_lang
      t.string :bearing
      t.string :nptg_locality_code
      t.string :locality_name
      t.string :parent_locality_name
      t.string :grand_parent_locality_name
      t.string :town
      t.string :town_lang
      t.string :suburb
      t.string :suburb_lang
      t.boolean :locality_centre
      t.string :grid_type
      t.float :easting
      t.float :northing
      t.float :lon
      t.float :lat
      t.string :stop_type
      t.string :bus_stop_type
      t.string :administrative_area_code
      t.datetime :creation_datetime
      t.datetime :modification_datetime
      t.integer :revision_number
      t.string :modification
      t.string :status

      t.timestamps
    end
  end

  def self.down
    drop_table :stops
  end
end
