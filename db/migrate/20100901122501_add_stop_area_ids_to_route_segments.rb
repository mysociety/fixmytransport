class AddStopAreaIdsToRouteSegments < ActiveRecord::Migration
  
  def self.up
    add_column :route_segments, :from_stop_area_id, :integer
    add_column :route_segments, :to_stop_area_id, :integer
  end

  def self.down
    remove_column :route_segments, :to_stop_area_id
    remove_column :route_segments, :from_stop_area_id
  end

end
