class RemoveReporterNameFromProblems < ActiveRecord::Migration
  def self.up
    remove_column :problems, :reporter_name
  end

  def self.down
    add_column :problems, :reporter_name, :string
  end
end
