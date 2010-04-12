class AddIndexesForStopAndAreaCodes < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX index_stops_on_atco_code_lower ON stops ((lower(atco_code)));"
    execute "CREATE INDEX index_stop_areas_on_code_lower ON stop_areas ((lower(code)));"
    add_index :stop_area_memberships, :stop_id, :name => 'index_stop_area_memberships_on_stop_id'
    add_index :stop_area_memberships, :stop_area_id, :name => 'index_stop_area_memberships_on_stop_area_id'
  end

  def self.down
    remove_index :stops, 'atco_code_lower'
    remove_index :stop_areas, 'code_lower'
    remove_index :stop_area_memberships, 'stop_id'
    remove_index :stop_area_memberships, 'stop_area_id'
  end
end
