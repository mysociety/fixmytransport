class AddHiddenFlagToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :is_hidden, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :users, :is_hidden
  end
end
