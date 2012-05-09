class AddDataGenerationColumnsToRouteSourceAdminArea < ActiveRecord::Migration
  def self.up
    add_column :route_source_admin_areas, :generation_low, :integer
    add_column :route_source_admin_areas, :generation_high, :integer
    add_column :route_source_admin_areas, :previous_id, :integer
    add_column :route_source_admin_areas, :persistent_id, :integer
    add_index :route_source_admin_areas, [:route_id, :generation_low, :generation_high]
  end

  def self.down
    remove_index :route_source_admin_areas, [:route_id, :generation_high, :generation_low]
    remove_column :route_source_admin_areas, :generation_low
    remove_column :route_source_admin_areas, :generation_high
    remove_column :route_source_admin_areas, :previous_id
    remove_column :route_source_admin_areas, :persistent_id
  end
end
