class AddCachedSlugToStops < ActiveRecord::Migration
  def self.up
    add_column :stops, :cached_slug, :string
    add_index :stops, :cached_slug
  end

  def self.down
    remove_column :stops, :cached_slug
  end
end
