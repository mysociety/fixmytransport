class AddStopAreaIndexesToRouteSegments < ActiveRecord::Migration
  def self.up
    add_index :route_segments, :from_stop_area_id
    add_index :route_segments, :to_stop_area_id
  end

  def self.down
    remove_index :route_segments, :from_stop_area_id
    remove_index :route_segments, :to_stop_area_id
  end
end
