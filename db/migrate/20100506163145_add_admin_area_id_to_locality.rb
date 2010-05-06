class AddAdminAreaIdToLocality < ActiveRecord::Migration
  def self.up
    add_column :localities, :admin_area_id, :integer
  end

  def self.down
    remove_column :localities, :admin_area_id
  end
end
