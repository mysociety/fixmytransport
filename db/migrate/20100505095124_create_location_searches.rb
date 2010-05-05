class CreateLocationSearches < ActiveRecord::Migration
  def self.up
    create_table :location_searches do |t|
      t.integer :transport_mode_id
      t.string :name
      t.string :area
      t.string :route_number
      t.string :location_type
      t.string :session_id
      t.text :events
      t.boolean :active
      t.timestamps
    end
  end

  def self.down
    drop_table :location_searches
  end
end
