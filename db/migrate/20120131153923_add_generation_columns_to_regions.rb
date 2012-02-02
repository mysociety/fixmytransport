class AddGenerationColumnsToRegions < ActiveRecord::Migration
  def self.up
    add_column :regions, :generation_low, :integer
    add_column :regions, :generation_high, :integer
    add_index :regions, [:cached_slug, :generation_low, :generation_high],  
                        :name => 'index_regions_on_slug_and_generations'
    execute "CREATE INDEX index_regions_on_name_lower_and_generations 
             ON regions (lower(name), generation_low, generation_high);"
  end

  def self.down
    remove_index :regions, "slug_and_generations"
    remove_index :regions, "name_lower_and_generations"
    remove_column :regions, :generation_low
    remove_column :regions, :generation_high
  end
end
