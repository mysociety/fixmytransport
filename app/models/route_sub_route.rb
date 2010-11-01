class RouteSubRoute < ActiveRecord::Base
  belongs_to :route
  belongs_to :sub_route
end
