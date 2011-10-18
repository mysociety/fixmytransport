class AddSuspendedFlagToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :is_suspended, :boolean, :default => false
    add_column :users, :suspended_notes, :text
  end

  def self.down
    remove_column :users, :is_suspended
    remove_column :users, :suspended_notes
  end
end