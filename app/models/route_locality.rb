class RouteLocality < ActiveRecord::Base
  belongs_to :route
  belongs_to :locality
end
