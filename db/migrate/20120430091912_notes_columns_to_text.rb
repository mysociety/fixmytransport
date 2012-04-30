class NotesColumnsToText < ActiveRecord::Migration
  def self.up
    change_column :operator_contacts, :notes, :text
    change_column :council_contacts, :notes, :text
    change_column :passenger_transport_executive_contacts, :notes, :text
  end

  def self.down
    change_column :operator_contacts, :notes, :string
    change_column :council_contacts, :notes, :string
    change_column :passenger_transport_executive_contacts, :notes, :string
  end
end
