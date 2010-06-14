class RenameStoryFields < ActiveRecord::Migration
  def self.up
    rename_column :stories, :subject, :title
    rename_column :stories, :description, :story
  end

  def self.down
    rename_column :stories, :title, :subject
    rename_column :stories, :story, :description    
  end
end
