class AddDataGenerationColumnsToPteAreas < ActiveRecord::Migration
  def self.up
    add_column :passenger_transport_executive_areas, :generation_low, :integer
    add_column :passenger_transport_executive_areas, :generation_high, :integer
    add_column :passenger_transport_executive_areas, :previous_id, :integer
    add_column :passenger_transport_executive_areas, :persistent_id, :integer
  end

  def self.down
    remove_column :passenger_transport_executive_areas, :generation_low
    remove_column :passenger_transport_executive_areas, :generation_high
    remove_column :passenger_transport_executive_areas, :previous_id
    remove_column :passenger_transport_executive_areas, :persistent_id
  end
end
