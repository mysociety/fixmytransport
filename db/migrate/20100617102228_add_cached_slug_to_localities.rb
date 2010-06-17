class AddCachedSlugToLocalities < ActiveRecord::Migration
  def self.up
    add_column :localities, :cached_slug, :string
    add_index :localities, :cached_slug
  end

  def self.down
    remove_column :localities, :cached_slug
  end
end
