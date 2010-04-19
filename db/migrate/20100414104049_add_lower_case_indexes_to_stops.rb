class AddLowerCaseIndexesToStops < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX index_stops_on_common_name_lower ON stops ((lower(common_name)));"
    execute "CREATE INDEX index_stops_on_locality_name_lower ON stops ((lower(locality_name)));"
    execute "CREATE INDEX index_stops_on_parent_locality_name_lower ON stops ((lower(parent_locality_name)));"
    execute "CREATE INDEX index_stops_on_grand_parent_locality_name_lower ON stops ((lower(grand_parent_locality_name)));"
  end

  def self.down
    remove_index :stops, 'common_name_lower'
    remove_index :stops, 'locality_name_lower'
    remove_index :stops, 'parent_locality_name_lower'
    remove_index :stops, 'grand_parent_locality_name_lower'
  end
end
