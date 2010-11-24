class AddIncomingMessageIdToOutgoingMessages < ActiveRecord::Migration
  def self.up
    add_column :outgoing_messages, :incoming_message_id, :integer
  end

  def self.down
    remove_column :outgoing_messages, :incoming_message_id
  end
end
