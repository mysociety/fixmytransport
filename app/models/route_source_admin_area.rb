class RouteSourceAdminArea < ActiveRecord::Base
  belongs_to :route
  belongs_to :source_admin_area, :class_name => 'AdminArea'
end