class AddGenerationColumnsToLocalityLinks < ActiveRecord::Migration
  def self.up
    add_column :locality_links, :generation_low, :integer
    add_column :locality_links, :generation_high, :integer
    add_column :locality_links, :previous_id, :integer
    add_column :locality_links, :persistent_id, :integer
    remove_index :locality_links, :ancestor_id
    remove_index :locality_links, :descendant_id
    add_index :locality_links, [:ancestor_id, :generation_low, :generation_high],
                              :name => 'index_locality_links_on_ancestor_id_and_gens'
    add_index :locality_links, [:descendant_id, :generation_low, :generation_high],
                              :name => 'index_locality_links_on_descendant_id_and_gens'
  end

  def self.down
    remove_column :locality_links, :generation_low
    remove_column :locality_links, :generation_high
    remove_column :locality_links, :previous_id
    remove_column :locality_links, :persistent_id
    add_index :locality_links, :ancestor_id
    add_index :locality_links, :descendant_id
  end
end
