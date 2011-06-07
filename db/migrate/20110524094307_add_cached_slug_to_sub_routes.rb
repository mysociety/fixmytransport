class AddCachedSlugToSubRoutes < ActiveRecord::Migration
  def self.up
    add_column :sub_routes, :cached_slug, :string
    add_index  :sub_routes, :cached_slug, :unique => true
    
  end

  def self.down
    remove_column :sub_routes, :cached_slug
  end
end
