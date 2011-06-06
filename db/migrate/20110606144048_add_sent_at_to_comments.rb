class AddSentAtToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :sent_at, :datetime
  end

  def self.down
    remove_column :comments, :sent_at
  end
end
