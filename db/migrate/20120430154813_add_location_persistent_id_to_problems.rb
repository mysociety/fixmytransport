class AddLocationPersistentIdToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :location_persistent_id, :integer
  end

  def self.down
    remove_column :problems, :location_persistent_id
  end
end
