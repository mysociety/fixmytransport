class AddDataGenerationColumnsToSubRoutes < ActiveRecord::Migration
  def self.up
    add_column :sub_routes, :generation_low, :integer
    add_column :sub_routes, :generation_high, :integer
    add_column :sub_routes, :previous_id, :integer
    remove_column :sub_routes, :from_station_persistent_id
    remove_column :sub_routes, :to_station_persistent_id
    execute("ALTER TABLE sub_routes
             ALTER COLUMN persistent_id
             DROP DEFAULT")
  end

  def self.down
    remove_column :sub_routes, :generation_low
    remove_column :sub_routes, :generation_high
    remove_column :sub_routes, :previous_id
    add_column :sub_routes, :from_station_persistent_id, :integer
    add_column :sub_routes, :to_station_persistent_id, :integer
    execute("ALTER TABLE sub_routes
             ALTER COLUMN persistent_id
             SET DEFAULT currval('sub_routes_id_seq')")
  end
end
