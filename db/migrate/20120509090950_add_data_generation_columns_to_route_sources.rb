class AddDataGenerationColumnsToRouteSources < ActiveRecord::Migration
  def self.up
    add_column :route_sources, :generation_low, :integer
    add_column :route_sources, :generation_high, :integer
    add_column :route_sources, :previous_id, :integer
    add_column :route_sources, :persistent_id, :integer
    add_index :route_sources, [:route_id, :generation_low, :generation_high],
                              :name => 'index_route_sources_on_route_id_and_gens'
  end

  def self.down
    remove_index :route_sources, :name => 'index_route_sources_on_route_id_and_gens'
    remove_column :route_sources, :generation_low
    remove_column :route_sources, :generation_high
    remove_column :route_sources, :previous_id
    remove_column :route_sources, :persistent_id
  end
end
