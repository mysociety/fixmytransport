class CreateStopAreas < ActiveRecord::Migration
  def self.up
    create_table :stop_areas do |t|
      t.string :code
      t.text :name
      t.string :administrative_area_code
      t.string :area_type
      t.string :grid_type
      t.float :easting
      t.float :northing
      t.datetime :creation_datetime
      t.datetime :modification_datetime
      t.integer :revision_number
      t.string :modification
      t.string :status

      t.timestamps
    end
  end

  def self.down
    drop_table :stop_areas
  end
end
