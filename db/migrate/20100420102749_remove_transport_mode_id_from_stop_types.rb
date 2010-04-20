class RemoveTransportModeIdFromStopTypes < ActiveRecord::Migration
  def self.up
    remove_column :stop_types, :transport_mode_id
  end

  def self.down
    add_column :stop_types, :transport_mode_id, :integer
  end
end
