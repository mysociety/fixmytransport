class AddGenerationColumnsToRouteOperators < ActiveRecord::Migration
  def self.up
    add_column :route_operators, :generation_low, :integer
    add_column :route_operators, :generation_high, :integer
    add_column :route_operators, :previous_id, :integer

    remove_index :route_operators, :operator_id
    remove_index :route_operators, :route_id

    add_index :route_operators, [:operator_id, :generation_low, :generation_high],
              :name => 'index_ro_on_operator_id_and_gens'
    add_index :route_operators, [:route_id, :generation_low, :generation_high],
              :name => 'index_ro_on_route_id_and_gens'

  end

  def self.down
    remove_column :route_operators, :generation_low
    remove_column :route_operators, :generation_high
    remove_column :route_operators, :previous_id

    add_index :route_operators, :operator_id
    add_index :route_operators, :route_id
  end
end
