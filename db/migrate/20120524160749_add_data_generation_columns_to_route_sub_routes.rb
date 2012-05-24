class AddDataGenerationColumnsToRouteSubRoutes < ActiveRecord::Migration
  def self.up
    add_column :route_sub_routes, :generation_low, :integer
    add_column :route_sub_routes, :generation_high, :integer
    add_column :route_sub_routes, :previous_id, :integer
    add_column :route_sub_routes, :persistent_id, :integer
  end

  def self.down
    remove_column :route_sub_routes, :generation_low
    remove_column :route_sub_routes, :generation_high
    remove_column :route_sub_routes, :previous_id
    remove_column :route_sub_routes, :persistent_id
  end
end
