class CreateRouteStops < ActiveRecord::Migration
  def self.up
    create_table :route_stops do |t|
      t.integer :route_id
      t.integer :stop_id

      t.timestamps
    end
  end

  def self.down
    drop_table :route_stops
  end
end
