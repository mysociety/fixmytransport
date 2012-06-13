class AddPtePersistentIdToPteContacts < ActiveRecord::Migration
  def self.up
    add_column :passenger_transport_executive_contacts, :passenger_transport_executive_persistent_id, :integer
  end

  def self.down
    remove_column :passenger_transport_executive_contacts, :passenger_transport_executive_persistent_id
  end
end
