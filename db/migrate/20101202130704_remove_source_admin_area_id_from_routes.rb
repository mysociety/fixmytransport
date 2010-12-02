class RemoveSourceAdminAreaIdFromRoutes < ActiveRecord::Migration
  def self.up
    remove_column :routes, :source_admin_area_id
  end

  def self.down
    add_column :routes, :source_admin_area_id, :integer
  end
end
