class RemoveTransportModeIdFromStopTypes < ActiveRecord::Migration
  def self.up
    remove_column :stop_types, :transport_mode_id
  end

  def self.down
    add_column :stop_types, :transport_mode_id, :integer
    add_foreign_key :stop_types, :transport_modes, { :dependent => :destroy } 
  end
end
