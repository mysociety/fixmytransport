class AddPersistenceIndexesToTables < ActiveRecord::Migration
  def self.up

    add_index :admin_areas, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_admin_areas_on_persistent_id_and_gens'
    add_index :admin_areas, :previous_id
    add_index :districts, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_districts_on_persistent_id_and_gens'
    add_index :districts, :previous_id
    add_index :journey_patterns, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_journey_patterns_on_persistent_id_and_gens'
    add_index :journey_patterns, :previous_id
    add_index :localities, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_localities_on_persistent_id_and_gens'
    add_index :localities, :previous_id
    add_index :operator_codes, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_operator_codes_on_persistent_id_and_gens'
    add_index :operator_codes, :previous_id
    add_index :regions, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_regions_on_persistent_id_and_gens'
    add_index :regions, :previous_id
    add_index :routes, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_routes_on_persistent_id_and_gens'
    add_index :routes, :previous_id
    add_index :route_operators, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_route_operators_on_persistent_id_and_gens'
    add_index :route_operators, :previous_id
    add_index :route_segments, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_route_segments_on_persistent_id_and_gens'
    add_index :route_segments, :previous_id
    add_index :stops, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_stops_on_persistent_id_and_gens'
    add_index :stops, :previous_id
    add_index :stop_areas, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_stop_areas_on_persistent_id_and_gens'
    add_index :stop_areas, :previous_id
    add_index :stop_area_memberships, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_stop_area_memberships_on_persistent_id_and_gens'
    add_index :vosa_licenses, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_vosa_licenses_on_persistent_id_and_gens'
    add_index :vosa_licenses, :previous_id
  end

  def self.down
    remove_index :admin_areas, :name => 'index_admin_areas_on_persistent_id_and_gens'
    remove_index :admin_areas, :previous_id
    remove_index :districts, :name => 'index_districts_on_persistent_id_and_gens'
    remove_index :districts, :previous_id
    remove_index :journey_patterns, :name => 'index_journey_patterns_on_persistent_id_and_gens'
    remove_index :journey_patterns, :previous_id
    remove_index :localities, :name => 'index_localities_on_persistent_id_and_gens'
    remove_index :localities, :previous_id
    remove_index :operator_codes, :name => 'index_operator_codes_on_persistent_id_and_gens'
    remove_index :operator_codes, :previous_id
    remove_index :regions, :name => 'index_regions_on_persistent_id_and_gens'
    remove_index :regions, :previous_id
    remove_index :routes, :name => 'index_routes_on_persistent_id_and_gens'
    remove_index :routes, :previous_id
    remove_index :route_operators, :name => 'index_route_operators_on_persistent_id_and_gens'
    remove_index :route_operators, :previous_id
    remove_index :route_segments, :name => 'index_route_segments_on_persistent_id_and_gens'
    remove_index :route_segments, :previous_id
    remove_index :stops, :name => 'index_stops_on_persistent_id_and_gens'
    remove_index :stops, :previous_id
    remove_index :stop_areas, :name => 'index_stop_areas_on_persistent_id_and_gens'
    remove_index :stop_areas, :previous_id
    remove_index :stop_area_memberships, :name => 'index_stop_area_memberships_on_persistent_id_and_gens'
    remove_index :vosa_licenses, :name => 'index_vosa_licenses_on_persistent_id_and_gens'
    remove_index :vosa_licenses, :previous_id
  end
end
