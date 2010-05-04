class AddForeignKeysToTransportModeStopAreaTypes < ActiveRecord::Migration
  def self.up
    add_foreign_key :transport_mode_stop_area_types, :transport_modes, { :dependent => :destroy } 
  end

  def self.down
    remove_foreign_key :transport_mode_stop_area_types, :transport_modes
  end
end
