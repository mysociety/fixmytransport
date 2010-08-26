class AddCachedSlugToCampaign < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :cached_slug, :string
    add_index :campaigns, :cached_slug
  end

  def self.down
    remove_column :campaigns, :cached_slug
  end
end
