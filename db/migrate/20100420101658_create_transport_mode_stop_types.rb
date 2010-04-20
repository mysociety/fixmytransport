class CreateTransportModeStopTypes < ActiveRecord::Migration
  def self.up
    create_table :transport_mode_stop_types do |t|
      t.integer :transport_mode_id
      t.integer :stop_type_id

      t.timestamps
    end
    add_foreign_key :transport_mode_stop_types, :stop_types, { :dependent => :nullify } 
    add_foreign_key :transport_mode_stop_types, :transport_modes, { :dependent => :nullify } 
  end

  def self.down
    drop_table :transport_mode_stop_types
  end
end
