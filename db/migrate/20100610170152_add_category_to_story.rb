class AddCategoryToStory < ActiveRecord::Migration
  def self.up
    add_column :stories, :category, :string
  end

  def self.down
    remove_column :stories, :category
  end
end
