class AddRegionIdToAdminAreas < ActiveRecord::Migration
  def self.up
    add_column :admin_areas, :region_id, :integer
    remove_column :admin_areas, :region_code
  end

  def self.down
    add_column :admin_areas, :region_code, :string
    remove_column :admin_areas, :region_id
  end
end
