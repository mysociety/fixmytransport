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
end
