class SetDefaultsOnUserBooleans < ActiveRecord::Migration
  def self.up
    change_column :users, :is_expert, :boolean, :default => false, :null => false
    change_column :users, :is_admin, :boolean, :default => false, :null => false
    change_column :users, :is_suspended, :boolean, :default => false, :null => false

  end

  def self.down
    change_column :users, :is_expert, :boolean
    change_column :users, :is_admin, :boolean
    change_column :users, :is_suspended, :boolean
  end
end
