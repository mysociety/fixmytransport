class AddRecipientFieldsToOutgoingMessage < ActiveRecord::Migration
  def self.up
    add_column :outgoing_messages, :recipient_id, :integer
    add_column :outgoing_messages, :recipient_type, :string
  end

  def self.down
    remove_column :outgoing_messages, :recipient_type
    remove_column :outgoing_messages, :recipient_id
  end
end
