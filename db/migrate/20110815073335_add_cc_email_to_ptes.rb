class AddCcEmailToPtes < ActiveRecord::Migration
  def self.up
    add_column :passenger_transport_executive_contacts, :cc_email, :string
  end

  def self.down
    remove_column :passenger_transport_executive_contacts, :cc_email
  end
end
