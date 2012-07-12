class AddOperatorCodeAndGenerationIndexToRouteSources < ActiveRecord::Migration
  def self.up
    add_index :route_sources, [:operator_code, :generation_low, :generation_high],
               :name => 'index_route_sources_on_operator_code_and_gens'
  end

  def self.down
    remove_index :route_sources, :name => 'index_route_sources_on_operator_code_and_gens'
  end
end
