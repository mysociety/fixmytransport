class AddIndexToSlugs < ActiveRecord::Migration
  def self.up 
    add_index :slugs, [:sluggable_id, :sluggable_type],  :name => 'index_slugs_on_sluggable_id_and_sluggable_type'
  end

  def self.down
    remove_index :slugs, 'sluggable_id_and_sluggable_type'
  end
end
