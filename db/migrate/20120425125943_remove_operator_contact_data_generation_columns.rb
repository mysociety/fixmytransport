class RemoveOperatorContactDataGenerationColumns < ActiveRecord::Migration
  def self.up
    remove_column :operator_contacts, :generation_low
    remove_column :operator_contacts, :generation_high
    remove_column :operator_contacts, :previous_id
  end

  def self.down
    add_column :operator_contacts, :generation_low, :integer
    add_column :operator_contacts, :generation_high, :integer
    add_column :operator_contacts, :previous_id, :integer
  end
end
