class AddCoordsToSubRoutes < ActiveRecord::Migration
  def self.up
    add_column :sub_routes, :lat, :float
    add_column :sub_routes, :lon, :float
    add_column :sub_routes, :coords, :point, :srid => 27700
    add_index :sub_routes, :coords, :spatial => true
  end

  def self.down
    remove_column :sub_routes, :coords
    remove_column :sub_routes, :lat
    remove_column :sub_routes, :lon
  end
end
