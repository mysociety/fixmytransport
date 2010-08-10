class AddProblemIdToAssignments < ActiveRecord::Migration
  def self.up
    add_column :assignments, :problem_id, :integer
  end

  def self.down
    remove_column :assignments, :problem_id
  end
end
