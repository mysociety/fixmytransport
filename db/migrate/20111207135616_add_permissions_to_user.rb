class AddPermissionsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :can_admin_locations, :boolean, :default => false, :null => :false
    add_column :users, :can_admin_users, :boolean, :default => false, :null => :false
    add_column :users, :can_admin_issues, :boolean, :default => false, :null => :false
    add_column :users, :can_admin_organizations, :boolean, :default => false, :null => :false
  end

  def self.down
    remove_column :users, :can_admin_locations
    remove_column :users, :can_admin_users
    remove_column :users, :can_admin_issues
    remove_column :users, :can_admin_organizations    
  end
end
