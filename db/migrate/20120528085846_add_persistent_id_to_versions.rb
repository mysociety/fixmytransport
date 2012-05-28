class AddPersistentIdToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :persistent_id, :integer
  end

  def self.down
    remove_column :versions, :persistent_id
  end
end
