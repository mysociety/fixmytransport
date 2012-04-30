class AddPersistentIdIndexes < ActiveRecord::Migration
  def self.up
    add_index :operator_contacts, :operator_persistent_id
    add_index :operators, [:persistent_id, :generation_low, :generation_high],
              :name => 'index_operators_on_persistent_id_and_gens'
  end

  def self.down
    remove_index :operator_contacts, :operator_persistent_id
    remove_index :operators, :name => 'index_operators_on_persistent_id_and_gens'
  end
end
