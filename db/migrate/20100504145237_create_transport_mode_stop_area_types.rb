class CreateTransportModeStopAreaTypes < ActiveRecord::Migration
  def self.up
    create_table :transport_mode_stop_area_types do |t|
      t.integer :transport_mode_id
      t.integer :stop_area_type_id

      t.timestamps
    end
  end

  def self.down
    drop_table :transport_mode_stop_area_types
  end
end
