class RouteSegment < ActiveRecord::Base
  belongs_to :from_stop, :class_name => 'Stop'
  belongs_to :to_stop, :class_name => 'Stop'
  belongs_to :route
  # virtual attribute used for adding new route segments
  attr_accessor :_add
  has_paper_trail
end
