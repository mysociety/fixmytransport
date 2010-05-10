class AddLowercaseIndexToNptgTables < ActiveRecord::Migration
  def self.up
      execute "CREATE INDEX index_localities_on_name_lower ON localities ((lower(name)));"
      execute "CREATE INDEX index_districts_on_name_lower ON districts ((lower(name)));"
      execute "CREATE INDEX index_regions_on_name_lower ON regions ((lower(name)));"
      execute "CREATE INDEX index_admin_areas_on_name_lower ON admin_areas ((lower(name)));"
  end

  def self.down
    remove_index :localities, 'name_lower'
    remove_index :districts, 'name_lower'
    remove_index :regions, 'name_lower'
    remove_index :admin_areas, 'name_lower'
  end
end
