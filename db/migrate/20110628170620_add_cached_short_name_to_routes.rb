class AddCachedShortNameToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :cached_short_name, :text
  end

  def self.down
    remove_column :routes, :cached_short_name
  end
end
