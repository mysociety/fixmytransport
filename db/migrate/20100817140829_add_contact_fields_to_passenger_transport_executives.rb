class AddContactFieldsToPassengerTransportExecutives < ActiveRecord::Migration
  def self.up
    add_column :passenger_transport_executives, :email, :text
    add_column :passenger_transport_executives, :email_confimed, :boolean
    add_column :passenger_transport_executives, :notes, :text
  end

  def self.down
    remove_column :passenger_transport_executives, :notes
    remove_column :passenger_transport_executives, :email_confimed
    remove_column :passenger_transport_executives, :email
  end
end
