class AddGenerationColumnsToAdminAreas < ActiveRecord::Migration
  def self.up
    add_column :admin_areas, :generation_low, :integer
    add_column :admin_areas, :generation_high, :integer
    add_column :admin_areas, :previous_id, :integer
    execute "CREATE INDEX index_admin_areas_on_name_lower_and_generations 
             ON admin_areas (lower(name), generation_low, generation_high);"
  end

  def self.down
    remove_index :admin_areas, "name_lower_and_generations"
    remove_column :admin_areas, :generation_low
    remove_column :admin_areas, :generation_high
    remove_column :admin_areas, :previous_id
  end
end
