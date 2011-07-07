class AddCachedSlugToStopAreas < ActiveRecord::Migration
  def self.up
    add_column :stop_areas, :cached_slug, :string
    add_index :stop_areas, :cached_slug
  end

  def self.down
    remove_column :stop_areas, :cached_slug
  end
end
