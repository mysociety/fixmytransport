class AddLatAndLonToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :lat, :float
    add_column :routes, :lon, :float
  end

  def self.down
    remove_column :routes, :lon
    remove_column :routes, :lat
  end
end
