class AddDataGenerationColumnsToStopAreaMemberships < ActiveRecord::Migration
  def self.up
    add_column :stop_area_memberships, :generation_low, :integer
    add_column :stop_area_memberships, :generation_high, :integer
    remove_index :stop_area_memberships, :stop_area_id
    remove_index :stop_area_memberships, :stop_id
    add_index :stop_area_memberships, [:stop_area_id, :generation_high, :generation_low],
              :name => 'index_sam_on_stop_area_id_and_gens'
    add_index :stop_area_memberships, [:stop_id, :generation_high, :generation_low],
              :name => 'index_sam_on_stop_id_and_gens'
  end

  def self.down
    remove_column :stop_area_memberships, :generation_low
    remove_column :stop_area_memberships, :generation_high
    add_index :stop_area_memberships, :stop_area_id
    add_index :stop_area_memberships, :stop_id
  end
end
