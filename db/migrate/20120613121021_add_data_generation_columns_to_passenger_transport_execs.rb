class AddDataGenerationColumnsToPassengerTransportExecs < ActiveRecord::Migration
  def self.up
    add_column :passenger_transport_executives, :generation_low, :integer
    add_column :passenger_transport_executives, :generation_high, :integer
    add_column :passenger_transport_executives, :previous_id, :integer
    add_column :passenger_transport_executives, :persistent_id, :integer
  end

  def self.down
    remove_column :passenger_transport_executives, :generation_low
    remove_column :passenger_transport_executives, :generation_high
    remove_column :passenger_transport_executives, :previous_id
    remove_column :passenger_transport_executives, :persistent_id
  end
end
