class AddJourneyPatternIndexToRouteSegments < ActiveRecord::Migration
  def self.up
    add_index :route_segments, :journey_pattern_id
  end

  def self.down
    remove_index :route_segments, :journey_pattern_id
  end
end
