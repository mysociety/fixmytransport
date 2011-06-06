class AddCommentIdToSentEmail < ActiveRecord::Migration
  def self.up
    add_column :sent_emails, :comment_id, :integer
  end

  def self.down
    remove_column :sent_emails, :comment_id
  end
end
