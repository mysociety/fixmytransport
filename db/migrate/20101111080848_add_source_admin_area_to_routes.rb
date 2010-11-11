class AddSourceAdminAreaToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :source_admin_area_id, :integer
  end

  def self.down
    remove_column :routes, :source_admin_area_id
  end
end
