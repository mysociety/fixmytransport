class AddOperatorCodeToRouteSourceAdminArea < ActiveRecord::Migration
  def self.up
    add_column :route_source_admin_areas, :operator_code, :string
  end

  def self.down
    remove_column :route_source_admin_areas, :operator_code
  end
end
