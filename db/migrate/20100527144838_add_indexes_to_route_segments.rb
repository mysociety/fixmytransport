class AddIndexesToRouteSegments < ActiveRecord::Migration
  def self.up
    add_index :route_segments, :route_id
    add_index :route_segments, :from_stop_id
    add_index :route_segments, :to_stop_id
  end

  def self.down
    remove_index :route_segments, :route_id
    remove_index :route_segments, :from_stop_id
    remove_index :route_segments, :to_stop_id
  end
end
