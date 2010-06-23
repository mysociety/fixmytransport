class AddCachedSlugToRoute < ActiveRecord::Migration
  def self.up
    add_column :routes, :cached_slug, :string
    add_index :routes, :cached_slug
  end

  def self.down
    remove_column :routes, :cached_slug
  end
end
