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
  # virtual attribute used for adding new route segments
  attr_accessor :_add
  has_paper_trail
end
