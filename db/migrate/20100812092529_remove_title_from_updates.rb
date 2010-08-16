class RemoveTitleFromUpdates < ActiveRecord::Migration
  def self.up
    remove_column :updates, :title
  end

  def self.down
    add_column :updates, :title, :integer
  end
end
