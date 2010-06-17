class AddCachedSlugToRegions < ActiveRecord::Migration
  def self.up
    add_column :regions, :cached_slug, :string
    add_index :regions, :cached_slug
  end

  def self.down
    remove_column :regions, :cached_slug
  end
end
