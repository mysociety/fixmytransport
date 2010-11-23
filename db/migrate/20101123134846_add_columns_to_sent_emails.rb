class AddColumnsToSentEmails < ActiveRecord::Migration
  def self.up
    add_column :sent_emails, :problem_id, :integer
    add_column :sent_emails, :recipient_type, :string
    add_column :sent_emails, :outgoing_message_id, :integer
  end

  def self.down
    remove_column :sent_emails, :outgoing_message_id
    remove_column :sent_emails, :recipient_type
    remove_column :sent_emails, :problem_id
  end
end
