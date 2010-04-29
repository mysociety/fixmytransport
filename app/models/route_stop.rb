# == Schema Information
# Schema version: 20100420165342
#
# Table name: route_stops
#
#  id         :integer         not null, primary key
#  route_id   :integer
#  stop_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

class RouteStop < ActiveRecord::Base
  belongs_to :stop
  belongs_to :route
  named_scope :terminuses, :conditions => {:terminus => true}
  
  def name
    if route.is_a? TrainRoute
      text = stop.name_without_station
    elsif route.is_a? MetroRoute
      text = stop.name_without_metro_station
    else
      text = stop.name_and_bearing
    end
    text
  end
  
end
