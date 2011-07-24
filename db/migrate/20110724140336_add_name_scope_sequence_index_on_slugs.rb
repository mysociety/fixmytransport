class AddNameScopeSequenceIndexOnSlugs < ActiveRecord::Migration
  def self.up
    add_index :slugs, [:name, :scope, :sequence], :name => 'index_slugs_on_name_scope_and_sequence'
  end

  def self.down
    remove_index :slugs, 'name_scope_and_sequence'
  end
end
