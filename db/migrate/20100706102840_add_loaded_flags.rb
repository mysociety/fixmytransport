class AddLoadedFlags < ActiveRecord::Migration
  def self.up
    add_column :stops, :loaded, :boolean
    add_column :stop_areas, :loaded, :boolean
    add_column :routes, :loaded, :boolean
  end

  def self.down
    remove_column :routes, :loaded
    remove_column :stop_areas, :loaded
    remove_column :stops, :loaded
  end
end
