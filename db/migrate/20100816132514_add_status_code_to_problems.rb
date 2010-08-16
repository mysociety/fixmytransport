class AddStatusCodeToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :status_code, :integer
    remove_column :problems, :confirmed
  end

  def self.down
    remove_column :problems, :status_code
    add_column :problems, :confirmed, :boolean
  end
end
