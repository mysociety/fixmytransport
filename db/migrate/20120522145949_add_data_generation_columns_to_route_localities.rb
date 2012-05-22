class AddDataGenerationColumnsToRouteLocalities < ActiveRecord::Migration
  def self.up
    add_column :route_localities, :generation_low, :integer
    add_column :route_localities, :generation_high, :integer
    add_column :route_localities, :previous_id, :integer
    add_column :route_localities, :persistent_id, :integer
  end

  def self.down
    remove_column :route_localities, :generation_low
    remove_column :route_localities, :generation_high
    remove_column :route_localities, :previous_id
    remove_column :route_localities, :persistent_id
  end
end