class AddGenerationColumnsToStops < ActiveRecord::Migration
  def self.up
    add_column :stops, :previous_id, :integer
    execute("DROP INDEX index_stops_on_atco_code_lower")
    remove_index :stops, :name => "index_stops_on_cached_slug"
    execute("DROP INDEX index_stops_on_common_name_lower")
    remove_index :stops, :name => "index_stops_on_crs_code" 
    remove_index :stops, :name => "index_stops_on_locality_and_stop_type"
    remove_index :stops, :name => "index_stops_on_locality_id"
    remove_index :stops, :name => "index_stops_on_metro_stop"
    remove_index :stops, :name => "index_stops_on_naptan_code"
    execute("DROP INDEX index_stops_on_other_code_lower")
    remove_index :stops, :name => "index_stops_on_stop_type"
    execute("DROP INDEX index_stops_on_street_lower")
    
    execute("CREATE INDEX index_stops_on_atco_code_lower_and_gens 
            ON stops (lower(atco_code), generation_low, generation_high);")
    add_index :stops, [:cached_slug, :generation_low, :generation_high],
                      :name => "index_stops_on_cached_slug_and_gens"
    execute("CREATE INDEX index_stops_on_common_name_lower_and_gens 
            ON stops (lower(common_name), generation_low, generation_high);")
    add_index :stops, [:crs_code, :generation_low, :generation_high],
                      :name => 'index_stops_on_crs_code_and_gens'
    add_index :stops, [:locality_id, :stop_type, :generation_low, :generation_high],
                      :name => 'index_stops_on_locality_id_stop_type_and_gens'
    add_index :stops, [:locality_id, :generation_low, :generation_high],
                      :name => 'index_stops_on_locality_id_and_gens'
    add_index :stops, [:metro_stop, :generation_low, :generation_high],
                      :name => 'index_stops_on_metro_stop_and_gens'
    add_index :stops, [:naptan_code, :generation_low, :generation_high],
                      :name => 'index_stops_on_naptan_code_and_gens'
    execute("CREATE INDEX index_stops_on_other_code_lower_and_gens 
            ON stops (lower(other_code), generation_low, generation_high);")
    add_index :stops, [:stop_type, :generation_low, :generation_high],
                      :name => 'index_stops_on_stop_type_and_gens'
    execute("CREATE INDEX index_stops_on_street_lower_and_gens 
            ON stops (lower(street), generation_low, generation_high);")
  end

  def self.down
    remove_index :stops, :name => 'index_stops_on_atco_code_lower_and_gens'
    remove_index :stops, :name => 'index_stops_on_cached_slug_and_gens'
    remove_index :stops, :name => 'index_stops_on_common_name_lower_and_gens'
    remove_index :stops, :name => 'index_stops_on_crs_code_and_gens'
    remove_index :stops, :name => 'index_stops_on_locality_id_stop_type_and_gens'
    remove_index :stops, :name => 'index_stops_on_locality_id_and_gens'
    remove_index :stops, :name => 'index_stops_on_metro_stop_and_gens'
    remove_index :stops, :name => 'index_stops_on_naptan_code_and_gens'
    remove_index :stops, :name => 'index_stops_on_other_code_lower_and_gens'
    remove_index :stops, :name => 'index_stops_on_stop_type_and_gens'
    remove_index :stops, :name => 'index_stops_on_street_lower_and_gens'


    execute "CREATE INDEX index_stops_on_atco_code_lower ON stops ((lower(atco_code)));"
    add_index :stops, :cached_slug
    execute "CREATE INDEX index_stops_on_common_name_lower ON stops ((lower(common_name)));"
    add_index :stops, :crs_code
    add_index :stops, [:locality_id, :stop_type]
    add_index :stops, :locality_id
    add_index :stops, :metro_stop
    add_index :stops, :naptan_code
    execute "CREATE INDEX index_stops_on_other_code_lower ON stops ((lower(other_code)));"
    add_index :stops, :stop_type
    execute "CREATE INDEX index_stops_on_street_lower ON stops ((lower(street)));"
    remove_column :stops, :previous_id
  end
end
