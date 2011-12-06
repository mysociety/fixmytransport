class AddVersionMetaData < ActiveRecord::Migration
  def self.up
    add_column :versions, :admin_action, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :versions, :admin_action
  end
end
