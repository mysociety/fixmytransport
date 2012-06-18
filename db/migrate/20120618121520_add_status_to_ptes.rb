class AddStatusToPtes < ActiveRecord::Migration
  def self.up
    add_column :passenger_transport_executives, :status, :string
  end

  def self.down
    remove_column :passenger_transport_executives, :status
  end
end
