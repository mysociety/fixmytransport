class CreateSubRoutes < ActiveRecord::Migration
  def self.up
    create_table :sub_routes do |t|
      t.integer :from_station_id
      t.integer :to_station_id
      t.string :departure_time

      t.timestamps
    end
  end

  def self.down
    drop_table :sub_routes
  end
end
