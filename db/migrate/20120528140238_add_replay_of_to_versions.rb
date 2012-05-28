class AddReplayOfToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :replay_of, :integer
  end

  def self.down
    remove_column :versions, :replay_of
  end
end
