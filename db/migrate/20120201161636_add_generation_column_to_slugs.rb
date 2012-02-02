class AddGenerationColumnToSlugs < ActiveRecord::Migration
  def self.up
    add_column :slugs, :generation_low, :integer
    add_column :slugs, :generation_high, :integer
    remove_index :slugs, "n_s_s_and_s"
    add_index :slugs, [:name, 
                       :sluggable_type, 
                       :sequence, 
                       :scope, 
                       :generation_low, 
                       :generation_high], :name => "index_slugs_on_n_s_s_s_and_g", :unique => true
    remove_index :slugs, "sluggable_id_and_sluggable_type"
    add_index :slugs, [:sluggable_id,
                       :sluggable_type, 
                       :generation_low,
                       :generation_high], :name => "index_slugs_on_s_s_and_g"
    remove_index :slugs, "sluggable_id"
    add_index :slugs, [:sluggable_id, 
                       :generation_high, 
                       :generation_low], :name => 'index_slugs_on_sluggable_id_and_generations'
    remove_index :slugs, "name_scope_and_sequence"
    add_index :slugs, [:name, 
                       :scope, 
                       :sequence,
                       :generation_high, 
                       :generation_low], :name => 'index_slugs_on_n_s_s_and_g'
  end

  def self.down
    remove_index :slugs, "n_s_s_and_g"
    add_index :slugs, [:name, :scope, :sequence], :name => 'index_slugs_on_name_scope_and_sequence'
    remove_index :slugs, "sluggable_id_and_generations"
    add_index :slugs, :sluggable_id, :name => 'index_slugs_on_sluggable_id'
    remove_index :slugs, "n_s_s_s_and_g"
    add_index :slugs, [:name, 
                       :sluggable_type, 
                       :sequence, :scope], :name => "index_slugs_on_n_s_s_and_s", :unique => true
    remove_index :slugs, "s_s_and_g"
    add_index :slugs, [:sluggable_id,
                       :sluggable_type], :name => "index_slugs_on_sluggable_id_and_sluggable_type"
    remove_column :slugs, :generation_low
    remove_column :slugs, :generation_high
  end
end
