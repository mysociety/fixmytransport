class AddRegionIdToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :region_id, :integer
    add_index :routes, :region_id
  end

  def self.down
    remove_column :routes, :region_id
  end
end
