class AddSluggablePersistentIdToSlugs < ActiveRecord::Migration
  def self.up
    add_column :slugs, :sluggable_persistent_id, :integer
  end

  def self.down
    remove_column :slugs, :sluggable_persistent_id
  end
end
