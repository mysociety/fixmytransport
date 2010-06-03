class AddIndexesToRouteLocalities < ActiveRecord::Migration
  def self.up
    add_index :route_localities, :locality_id
    add_index :route_localities, :route_id 
  end

  def self.down
    remove_index :route_localities, :locality_id
    remove_index :route_localities, :route_id
  end
end
