class AddCcEmailToOperatorContacts < ActiveRecord::Migration
  def self.up
    add_column :operator_contacts, :cc_email, :string
  end

  def self.down
    remove_column :operator_contacts, :cc_email
  end
end
