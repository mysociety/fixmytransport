class AddTransportModeIdToSubRoute < ActiveRecord::Migration
  def self.up
    add_column :sub_routes, :transport_mode_id, :integer
  end

  def self.down
    remove_column :sub_routes, :transport_mode_id
  end
end
