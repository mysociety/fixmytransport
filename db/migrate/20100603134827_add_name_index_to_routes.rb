class AddNameIndexToRoutes < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX index_routes_on_name_lower ON routes ((lower(name)));"
  end

  def self.down
    remove_index :routes, 'name_lower'
  end
end
