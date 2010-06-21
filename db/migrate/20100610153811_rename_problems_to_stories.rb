class RenameProblemsToStories < ActiveRecord::Migration
  def self.up
    rename_table :problems, :stories
    execute "ALTER TABLE problems_id_seq RENAME TO stories_id_seq"
  end

  def self.down
    rename_table :stories, :problems
    execute "ALTER TABLE stories_id_seq RENAME TO problems_id_seq"
  end
end
