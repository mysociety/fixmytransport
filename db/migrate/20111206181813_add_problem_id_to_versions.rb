class AddProblemIdToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :problem_id, :integer
  end

  def self.down
    remove_column :versions, :problem_id
  end
end
