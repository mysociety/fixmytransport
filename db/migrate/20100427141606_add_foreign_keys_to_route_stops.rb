class AddForeignKeysToRouteStops< ActiveRecord::Migration
  def self.up
    add_foreign_key :route_stops, :routes, { :dependent => :destroy } 
    add_foreign_key :route_stops, :stops, { :dependent => :destroy } 
  end

  def self.down
    remove_foreign_key :route_stops, { :column => :stop_id }
    remove_foreign_key :route_stops, { :column => :route_id }
  end
end
