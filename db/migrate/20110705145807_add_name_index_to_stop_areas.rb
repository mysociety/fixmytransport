class AddNameIndexToStopAreas < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX index_stop_areas_on_name_lower ON stop_areas ((lower(name)));"
  end

  def self.down
    remove_index :stop_areas, 'name_lower'
  end
end
