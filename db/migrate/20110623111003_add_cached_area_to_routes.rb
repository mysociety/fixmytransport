class AddCachedAreaToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :cached_area, :text
  end

  def self.down
    remove_column :routes, :cached_area
  end
end
