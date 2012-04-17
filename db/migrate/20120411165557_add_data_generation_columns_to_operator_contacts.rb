class AddDataGenerationColumnsToOperatorContacts < ActiveRecord::Migration
  def self.up
    add_column :operator_contacts, :generation_low, :integer
    add_column :operator_contacts, :generation_high, :integer
    add_column :operator_contacts, :previous_id, :integer
  end

  def self.down
    remove_column :operator_contacts, :generation_low
    remove_column :operator_contacts, :generation_high
    remove_column :operator_contacts, :previous_id
  end
end
