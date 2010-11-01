class CreateRouteSubRoutes < ActiveRecord::Migration
  def self.up
    create_table :route_sub_routes do |t|
      t.integer :route_id
      t.integer :sub_route_id

      t.timestamps
    end
  end

  def self.down
    drop_table :route_sub_routes
  end
end
