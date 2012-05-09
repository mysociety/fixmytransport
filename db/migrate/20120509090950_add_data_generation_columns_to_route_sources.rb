class AddDataGenerationColumnsToRouteSources < ActiveRecord::Migration
  def self.up
    add_column :route_sources, :generation_low, :integer
    add_column :route_sources, :generation_high, :integer
    add_column :route_sources, :previous_id, :integer
    add_column :route_sources, :persistent_id, :integer
    add_index :route_sources, [:route_id, :generation_low, :generation_high]
  end

  def self.down
    remove_index :route_sources, [:route_id, :generation_high, :generation_low]
    remove_column :route_sources, :generation_low
    remove_column :route_sources, :generation_high
    remove_column :route_sources, :previous_id
    remove_column :route_sources, :persistent_id
  end
end
