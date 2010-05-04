class AddIndexesToRouteStops < ActiveRecord::Migration
  def self.up
    add_index :route_stops, :stop_id
    add_index :route_stops, :route_id
  end

  def self.down
    remove_index :route_stops, :stop_id
    remove_index :route_stops, :route_id
  end
end
