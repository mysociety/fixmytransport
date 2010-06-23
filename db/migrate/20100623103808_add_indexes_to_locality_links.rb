class AddIndexesToLocalityLinks < ActiveRecord::Migration
  def self.up
    add_index :locality_links, :ancestor_id
    add_index :locality_links, :descendant_id
  end

  def self.down
    remove_index :locality_links, :ancestor_id
    remove_index :locality_links, :descendant_id
  end
end
