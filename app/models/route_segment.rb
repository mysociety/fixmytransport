class RouteSegment < ActiveRecord::Base
  belongs_to :from_stop, :class_name => 'Stop'
  belongs_to :to_stop, :class_name => 'Stop'
  belongs_to :route
  
end
