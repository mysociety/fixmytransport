class AddGenerationColumnsToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :generation_low, :integer
    add_column :routes, :generation_high, :integer
    add_column :routes, :previous_id, :integer

    remove_index :routes, :cached_slug
    execute("DROP INDEX index_routes_on_name_lower")
    remove_index :routes, :number
    execute("DROP INDEX index_routes_on_number_lower")
    remove_index :routes, :operator_code
    remove_index :routes, :region_id
    remove_index :routes, :transport_mode_id
    remove_index :routes, :type

    add_index :routes, [:cached_slug, :generation_low, :generation_high],
              :name => 'index_routes_on_cached_slug_and_gens'
    execute("CREATE INDEX index_routes_on_name_lower_and_gens
            ON routes (lower(name), generation_low, generation_high);")
    add_index :routes, [:number, :generation_low, :generation_high],
              :name => 'index_routes_on_number_and_gens'
    execute("CREATE INDEX index_routes_on_number_lower_and_gens
            ON routes (lower(number), generation_low, generation_high);")
    add_index :routes, [:operator_code, :generation_low, :generation_high],
              :name => 'index_routes_on_operator_code_and_gens'
    add_index :routes, [:region_id, :generation_low, :generation_high],
              :name => 'index_routes_on_region_id_and_gens'
    add_index :routes, [:transport_mode_id, :generation_low, :generation_high],
              :name => 'index_routes_on_transport_mode_id_and_gens'
    add_index :routes, [:type, :generation_low, :generation_high],
              :name => 'index_routes_on_type_and_gens'
  end

  def self.down
    remove_column :routes, :generation_low
    remove_column :routes, :generation_high
    remove_column :routes, :previous_id

    add_index :routes, :cached_slug
    execute("CREATE INDEX index_routes_on_name_lower
             ON routes (lower(name));")
    add_index :routes, :number
    execute("CREATE INDEX index_routes_on_number_lower
             ON routes (lower(number));")
    add_index :routes, :operator_code
    add_index :routes, :region_id
    add_index :routes, :transport_mode_id
    add_index :routes, :type

  end
end
