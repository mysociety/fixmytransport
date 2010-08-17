class CreatePassengerTransportExecutiveAreas < ActiveRecord::Migration
  def self.up
    create_table :passenger_transport_executive_areas do |t|
      t.integer :area_id
      t.integer :passenger_transport_executive_id

      t.timestamps
    end
  end

  def self.down
    drop_table :passenger_transport_executive_areas
  end
end
