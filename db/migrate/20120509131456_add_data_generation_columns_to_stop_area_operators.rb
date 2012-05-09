class AddDataGenerationColumnsToStopAreaOperators < ActiveRecord::Migration
  def self.up
    add_column :stop_area_operators, :generation_low, :integer
    add_column :stop_area_operators, :generation_high, :integer
    add_column :stop_area_operators, :previous_id, :integer
    add_column :stop_area_operators, :persistent_id, :integer
    add_index :stop_area_operators, [:stop_area_id, :generation_low, :generation_high]
    add_index :stop_area_operators, [:operator_id, :generation_low, :generation_high]
  end

  def self.down
    remove_index :stop_area_operators, [:stop_area_id, :generation_low, :generation_high]
    remove_index :stop_area_operators, [:operator_id, :generation_low, :generation_high]
    remove_column :stop_area_operators, :generation_low
    remove_column :stop_area_operators, :generation_high
    remove_column :stop_area_operators, :previous_id
    remove_column :stop_area_operators, :persistent_id
  end
end
