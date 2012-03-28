class RouteSource < ActiveRecord::Base
  belongs_to :region
  belongs_to :route
end