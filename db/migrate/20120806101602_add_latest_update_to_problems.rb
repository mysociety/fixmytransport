class AddLatestUpdateToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :latest_update_at, :datetime
  end

  def self.down
    remove_column :problems, :latest_update_at
  end
end
