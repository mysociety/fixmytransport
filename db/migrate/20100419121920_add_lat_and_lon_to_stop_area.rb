class AddLatAndLonToStopArea < ActiveRecord::Migration
  def self.up
    add_column :stop_areas, :lon, :float
    add_column :stop_areas, :lat, :float
  end

  def self.down
    remove_column :stop_areas, :lat
    remove_column :stop_areas, :lon
  end
end
