class AddForeignKeyToStopTypes < ActiveRecord::Migration
  def self.up
    add_foreign_key :stop_types, :transport_modes, { :dependent => :destroy } 
  end

  def self.down
    remove_foreign_key :stop_types, :transport_modes
  end
end
