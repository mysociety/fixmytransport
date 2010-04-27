class AddTerminusToRouteStops < ActiveRecord::Migration
  def self.up
    add_column :route_stops, :terminus, :boolean
  end

  def self.down
    remove_column :route_stops, :terminus
  end
end
