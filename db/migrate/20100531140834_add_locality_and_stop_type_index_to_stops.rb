class AddLocalityAndStopTypeIndexToStops < ActiveRecord::Migration
  def self.up
     add_index :stops, [:locality_id, :stop_type],  :name => 'index_stops_on_locality_and_stop_type'
  end

  def self.down
    remove_index :stops, 'locality_and_stop_type'
  end
end
