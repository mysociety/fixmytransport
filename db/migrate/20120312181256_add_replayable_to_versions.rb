class AddReplayableToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :replayable, :boolean
    add_index :versions, [:replayable, :item_type]
  end

  def self.down
    remove_column :versions, :replayable
  end
end
