class AddGenerationColumnsToDistricts < ActiveRecord::Migration
  def self.up
    add_column :districts, :generation_low, :integer
    add_column :districts, :generation_high, :integer
    add_column :districts, :previous_id, :integer
    execute "CREATE INDEX index_districts_on_name_lower_and_generations 
             ON districts (lower(name), generation_low, generation_high);"
  end

  def self.down
    remove_index :districts, "name_lower_and_generations"
    remove_column :districts, :generation_low
    remove_column :districts, :generation_high
    remove_column :districts, :previous_id
  end
end
