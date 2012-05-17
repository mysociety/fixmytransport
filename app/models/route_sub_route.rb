class RouteSubRoute < ActiveRecord::Base
  belongs_to :route, :conditions => Route.data_generation_conditions
  belongs_to :sub_route
end
