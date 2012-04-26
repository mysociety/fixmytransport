class AddPersistentOperatorIdToOperatorContacts < ActiveRecord::Migration
  def self.up
    add_column :operator_contacts, :operator_persistent_id, :integer
  end

  def self.down
    remove_column :operator_contacts, :operator_persistent_id
  end
end
