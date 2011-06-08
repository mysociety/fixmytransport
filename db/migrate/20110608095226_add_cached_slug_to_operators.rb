class AddCachedSlugToOperators < ActiveRecord::Migration
  def self.up
    add_column :operators, :cached_slug, :string
    add_index :operators, :cached_slug
  end

  def self.down
    remove_column :operators, :cached_slug
  end
end
