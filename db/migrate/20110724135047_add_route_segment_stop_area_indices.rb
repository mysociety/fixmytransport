class AddRouteSegmentStopAreaIndices < ActiveRecord::Migration
  def self.up
    add_index :route_segments, [:route_id, :from_stop_area_id], :name => 'index_route_segments_on_from_stop_area_and_route'
    add_index :route_segments, [:route_id, :to_stop_area_id], :name => 'index_route_segments_on_to_stop_area_and_route'

  end

  def self.down
    remove_index :route_segments, "from_stop_area_and_route"
    remove_index :route_segments, "to_stop_area_and_route"
  end
end
