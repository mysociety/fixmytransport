class RemoveIsAdminFlagFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :is_admin
  end

  def self.down
    add_column :users, :is_admin, :boolean
  end
end
