class AddPersistentIdToDataGenerationModels < ActiveRecord::Migration
  def self.up
    add_column :admin_areas, :persistent_id, :integer
    add_column :districts, :persistent_id, :integer
    add_column :journey_patterns, :persistent_id, :integer
    add_column :localities, :persistent_id, :integer
    add_column :operators, :persistent_id, :integer
    add_column :operator_codes, :persistent_id, :integer
    add_column :regions, :persistent_id, :integer
    add_column :routes, :persistent_id, :integer
    add_column :route_operators, :persistent_id, :integer
    add_column :route_segments, :persistent_id, :integer
    add_column :stops, :persistent_id, :integer
    add_column :stop_areas, :persistent_id, :integer
    add_column :stop_area_memberships, :persistent_id, :integer
    add_column :vosa_licenses, :persistent_id, :integer
  end

  def self.down
    remove_column :admin_areas, :persistent_id
    remove_column :districts, :persistent_id
    remove_column :journey_patterns, :persistent_id
    remove_column :localities, :persistent_id
    remove_column :operators, :persistent_id
    remove_column :operator_codes, :persistent_id
    remove_column :regions, :persistent_id
    remove_column :routes, :persistent_id
    remove_column :route_operators, :persistent_id
    remove_column :route_segments, :persistent_id
    remove_column :stops, :persistent_id
    remove_column :stop_areas, :persistent_id
    remove_column :stop_area_memberships, :persistent_id
    remove_column :vosa_licenses, :persistent_id
  end
end
