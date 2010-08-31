class AddMetroStopToStops < ActiveRecord::Migration
  def self.up
    add_column :stops, :metro_stop, :boolean, :default => false
    add_index :stops, :metro_stop
  end

  def self.down
    remove_index :stops, :metro_stop
    remove_column :stops, :metro_stop
  end
end
