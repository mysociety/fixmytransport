class CreatePassengerTransportExecutiveContacts < ActiveRecord::Migration
  def self.up
    create_table :passenger_transport_executive_contacts do |t|
      t.integer :passenger_transport_executive_id
      t.string :category 
      t.string :email
      t.string :location_type
      t.boolean :confirmed, :default => false
      t.boolean :deleted, :default => false
      t.string :notes
      t.timestamps
    end
    add_index :passenger_transport_executive_contacts, :passenger_transport_executive_id, :name => 'pte_contacts_index_on_pte_id'
  end

  def self.down
    drop_table :passenger_transport_executive_contacts
  end
end
