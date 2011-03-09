# == Schema Information
# Schema version: 20100707152350
#
# Table name: route_segments
#
#  id            :integer         not null, primary key
#  from_stop_id  :integer
#  to_stop_id    :integer
#  from_terminus :boolean
#  to_terminus   :boolean
#  route_id      :integer
#  created_at    :datetime
#  updated_at    :datetime
#

class RouteSegment < ActiveRecord::Base
  belongs_to :from_stop, :class_name => 'Stop'
  belongs_to :to_stop, :class_name => 'Stop'
  belongs_to :from_stop_area, :class_name => 'StopArea'
  belongs_to :to_stop_area, :class_name => 'StopArea'
  belongs_to :route
  belongs_to :journey_pattern
  # virtual attribute used for adding new route segments
  attr_accessor :_add
  before_save :set_stop_areas
  has_paper_trail
  
  def set_stop_areas
    station_part_stops = StopType.station_part_types
    station_types = StopType.station_part_types_to_station_types

    if ! from_stop_area
      if station_part_stops.include?(from_stop.stop_type)
        self.from_stop_area = from_stop.root_stop_area(station_types[from_stop.stop_type])
      end
    end
    if ! to_stop_area
      if station_part_stops.include?(to_stop.stop_type)
        self.to_stop_area = to_stop.root_stop_area(station_types[to_stop.stop_type])
      end
    end
  end
  
end
