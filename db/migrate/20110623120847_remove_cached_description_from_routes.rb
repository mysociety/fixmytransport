class RemoveCachedDescriptionFromRoutes < ActiveRecord::Migration
  def self.up
    remove_column :routes, :cached_description
  end

  def self.down
    add_column :routes, :cached_description, :text
  end
end
