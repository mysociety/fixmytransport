class AddCachedDescriptionToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :cached_description, :text
  end

  def self.down
    remove_column :routes, :cached_description
  end
end
