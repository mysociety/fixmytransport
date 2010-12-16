class AddDeletedToContacts < ActiveRecord::Migration
  def self.up
    add_column :council_contacts, :deleted, :boolean, :default => false, :null => false
    add_column :operator_contacts, :deleted, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :operator_contacts, :deleted 
    remove_column :council_contacts, :deleted
  end
end
