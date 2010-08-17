class CreatePassengerTransportExecutives < ActiveRecord::Migration
  def self.up
    create_table :passenger_transport_executives do |t|
      t.string :name
      t.string :wikipedia_url
      t.timestamps
    end
  end

  def self.down
    drop_table :passenger_transport_executives
  end
end
