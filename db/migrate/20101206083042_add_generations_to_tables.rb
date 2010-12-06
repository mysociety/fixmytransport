class AddGenerationsToTables < ActiveRecord::Migration
  def self.up
    add_column :stop_areas, :generation_low, :integer, :default => 1, :null => false
    add_column :stop_areas, :generation_high, :integer, :default => 1, :null => false
    add_column :stop_area_memberships, :generation_low, :integer, :default => 1, :null => false
    add_column :stop_area_memberships, :generation_high, :integer, :default => 1, :null => false
    add_column :stop_area_links, :generation_low, :integer, :default => 1, :null => false
    add_column :stop_area_links, :generation_high, :integer, :default => 1, :null => false
    add_column :regions, :generation_low, :integer, :default => 1, :null => false
    add_column :regions, :generation_high, :integer, :default => 1, :null => false
    add_column :admin_areas, :generation_low, :integer, :default => 1, :null => false
    add_column :admin_areas, :generation_high, :integer, :default => 1, :null => false
    add_column :districts, :generation_low, :integer, :default => 1, :null => false
    add_column :districts, :generation_high, :integer, :default => 1, :null => false
    add_column :localities, :generation_low, :integer, :default => 1, :null => false
    add_column :localities, :generation_high, :integer, :default => 1, :null => false
    add_column :locality_links, :generation_low, :integer, :default => 1, :null => false
    add_column :locality_links, :generation_high, :integer, :default => 1, :null => false
    add_column :alternative_names, :generation_low, :integer, :default => 1, :null => false
    add_column :alternative_names, :generation_high, :integer, :default => 1, :null => false
    add_column :routes, :generation_low, :integer, :default => 1, :null => false
    add_column :routes, :generation_high, :integer, :default => 1, :null => false
    add_column :route_segments, :generation_low, :integer, :default => 1, :null => false
    add_column :route_segments, :generation_high, :integer, :default => 1, :null => false
    add_column :route_operators, :generation_low, :integer, :default => 1, :null => false
    add_column :route_operators, :generation_high, :integer, :default => 1, :null => false
    add_column :operators, :generation_low, :integer, :default => 1, :null => false
    add_column :operators, :generation_high, :integer, :default => 1, :null => false
  end

  def self.down
    remove_column :stop_areas, :generation_low
    remove_column :stop_areas, :generation_high
    remove_column :stop_area_memberships, :generation_low
    remove_column :stop_area_memberships, :generation_high
    remove_column :stop_area_links, :generation_low
    remove_column :stop_area_links, :generation_high
    remove_column :regions, :generation_low
    remove_column :regions, :generation_high
    remove_column :admin_areas, :generation_low
    remove_column :admin_areas, :generation_high
    remove_column :districts, :generation_low
    remove_column :districts, :generation_high
    remove_column :localities, :generation_low
    remove_column :localities, :generation_high
    remove_column :locality_links, :generation_low
    remove_column :locality_links, :generation_high
    remove_column :alternative_names, :generation_low
    remove_column :alternative_names, :generation_high
    remove_column :routes, :generation_low
    remove_column :routes, :generation_high
    remove_column :route_segments, :generation_low
    remove_column :route_segments, :generation_high
    remove_column :route_operators, :generation_low
    remove_column :route_operators, :generation_high
    remove_column :operators, :generation_low
    remove_column :operators, :generation_high
  end
end
