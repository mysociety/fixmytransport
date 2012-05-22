# == Schema Information
# Schema version: 20100707152350
#
# Table name: route_localities
#
#  id          :integer         not null, primary key
#  locality_id :integer
#  route_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#

class RouteLocality < ActiveRecord::Base
  belongs_to :route
  belongs_to :locality
  exists_in_data_generation()
end
