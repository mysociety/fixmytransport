class AddDataGenerationColumnsToRouteSourceAdminArea < ActiveRecord::Migration
  def self.up
    add_column :route_source_admin_areas, :generation_low, :integer
    add_column :route_source_admin_areas, :generation_high, :integer
    add_column :route_source_admin_areas, :previous_id, :integer
    add_column :route_source_admin_areas, :persistent_id, :integer
    add_index :route_source_admin_areas, [:route_id, :generation_low, :generation_high],
                                        :name => 'index_route_source_admin_area_on_route_id_and_gens'
  end

  def self.down
    remove_index :route_source_admin_areas, :name => 'index_route_source_admin_area_on_route_id_and_gens'
    remove_column :route_source_admin_areas, :generation_low
    remove_column :route_source_admin_areas, :generation_high
    remove_column :route_source_admin_areas, :previous_id
    remove_column :route_source_admin_areas, :persistent_id
  end
end
