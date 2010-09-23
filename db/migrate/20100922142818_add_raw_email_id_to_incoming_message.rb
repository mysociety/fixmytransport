class AddRawEmailIdToIncomingMessage < ActiveRecord::Migration
  def self.up
    add_column :incoming_messages, :raw_email_id, :integer
  end

  def self.down
    remove_column :incoming_messages, :raw_email_id
  end
end
