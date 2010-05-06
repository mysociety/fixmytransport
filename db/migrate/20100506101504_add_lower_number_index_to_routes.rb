class AddLowerNumberIndexToRoutes < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX index_routes_on_number_lower ON routes ((lower(number)));"
  end

  def self.down
    remove_index :routes, 'number_lower'
  end
end

