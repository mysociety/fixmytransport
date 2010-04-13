class AddTransportModeIdToStopTypes < ActiveRecord::Migration
  def self.up
    remove_column :stop_types, :mode
    add_column :stop_types, :transport_mode_id, :integer
  end

  def self.down
    add_column :stop_types, :mode, :string
    remove_column :stop_types, :transport_mode_id
  end
end
