class AddUserSeenFlagsToIssues < ActiveRecord::Migration
  def self.up
    add_column :problems, :reporter_seen, :boolean, :default => false, :null => false
    add_column :campaigns, :initiator_seen, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :problems, :reporter_seen
    remove_column :campaigns, :initiator_seen
  end
end
