class AddPersistentIdsToSubRoutes < ActiveRecord::Migration
  def self.up
    add_column :sub_routes, :from_station_persistent_id, :integer
    add_column :sub_routes, :to_station_persistent_id, :integer
  end

  def self.down
    remove_column :sub_routes, :from_station_persistent_id
    remove_column :sub_routes, :to_station_persistent_id
  end
end
