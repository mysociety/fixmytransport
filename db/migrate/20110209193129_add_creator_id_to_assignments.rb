class AddCreatorIdToAssignments < ActiveRecord::Migration
  def self.up
    add_column :assignments, :creator_id, :integer
  end

  def self.down
    remove_column :assignments, :creator_id
  end
end
