class AddStopIdToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :stop_id, :integer
  end

  def self.down
    remove_column :problems, :stop_id
  end
end
