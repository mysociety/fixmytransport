class AddDataGenerationColumnsToOperators < ActiveRecord::Migration
  def self.up
    add_column :operators, :generation_low, :integer
    add_column :operators, :generation_high, :integer
    add_column :operators, :previous_id, :integer
    remove_index :operators, :cached_slug
    add_index :operators, [:cached_slug, :generation_low, :generation_high],
              :name => 'index_operators_on_cached_slug_and_gens'
  end

  def self.down
    remove_column :operators, :generation_low, :integer
    remove_column :operators, :generation_high, :integer
    remove_column :operators, :previous_id, :integer
    remove_index :operators, :name => 'index_operators_on_cached_slug_and_gens'
    add_index :operators, :cached_slug
  end
end
