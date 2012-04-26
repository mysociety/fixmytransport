class AddPersistenceIndexesToTables < ActiveRecord::Migration
  def self.up

    add_index :admin_areas, [:persistent_id, :generation_low, :generation_high]
    add_index :admin_areas, :previous_id
    add_index :districts, [:persistent_id, :generation_low, :generation_high]
    add_index :districts, :previous_id
    add_index :journey_patterns, [:persistent_id, :generation_low, :generation_high]
    add_index :journey_patterns, :previous_id
    add_index :localities, [:persistent_id, :generation_low, :generation_high]
    add_index :localities, :previous_id
    add_index :operator_codes, [:persistent_id, :generation_low, :generation_high]
    add_index :operator_codes, :previous_id
    add_index :regions, [:persistent_id, :generation_low, :generation_high]
    add_index :regions, :previous_id
    add_index :routes, [:persistent_id, :generation_low, :generation_high]
    add_index :routes, :previous_id
    add_index :route_operators, [:persistent_id, :generation_low, :generation_high]
    add_index :route_operators, :previous_id
    add_index :route_segments, [:persistent_id, :generation_low, :generation_high]
    add_index :route_segments, :previous_id
    add_index :stops, [:persistent_id, :generation_low, :generation_high]
    add_index :stops, :previous_id
    add_index :stop_areas, [:persistent_id, :generation_low, :generation_high]
    add_index :stop_areas, :previous_id
    add_index :stop_area_memberships, [:persistent_id, :generation_low, :generation_high]
    add_index :vosa_licenses, [:persistent_id, :generation_low, :generation_high]
    add_index :vosa_licenses, :previous_id
  end

  def self.down
    remove_index :admin_areas, [:persistent_id, :generation_low, :generation_high]
    remove_index :admin_areas, :previous_id
    remove_index :districts, [:persistent_id, :generation_low, :generation_high]
    remove_index :districts, :previous_id
    remove_index :journey_patterns, [:persistent_id, :generation_low, :generation_high]
    remove_index :journey_patterns, :previous_id
    remove_index :localities, [:persistent_id, :generation_low, :generation_high]
    remove_index :localities, :previous_id
    remove_index :operator_codes, [:persistent_id, :generation_low, :generation_high]
    remove_index :operator_codes, :previous_id
    remove_index :regions, [:persistent_id, :generation_low, :generation_high]
    remove_index :regions, :previous_id
    remove_index :routes, [:persistent_id, :generation_low, :generation_high]
    remove_index :routes, :previous_id
    remove_index :route_operators, [:persistent_id, :generation_low, :generation_high]
    remove_index :route_operators, :previous_id
    remove_index :route_segments, [:persistent_id, :generation_low, :generation_high]
    remove_index :route_segments, :previous_id
    remove_index :stops, [:persistent_id, :generation_low, :generation_high]
    remove_index :stops, :previous_id
    remove_index :stop_areas, [:persistent_id, :generation_low, :generation_high]
    remove_index :stop_areas, :previous_id
    remove_index :stop_area_memberships, [:persistent_id, :generation_low, :generation_high]
    remove_index :vosa_licenses, [:persistent_id, :generation_low, :generation_high]
    remove_index :vosa_licenses, :previous_id
  end
end
