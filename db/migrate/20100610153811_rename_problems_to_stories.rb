class RenameProblemsToStories < ActiveRecord::Migration
  def self.up
    rename_table :problems, :stories
  end

  def self.down
    rename_table :stories, :problems
  end
end
