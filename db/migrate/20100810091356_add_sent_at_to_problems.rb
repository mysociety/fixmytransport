class AddSentAtToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :sent_at, :datetime
  end

  def self.down
    remove_column :problems, :sent_at
  end
end
