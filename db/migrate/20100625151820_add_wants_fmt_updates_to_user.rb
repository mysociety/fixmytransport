class AddWantsFmtUpdatesToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :wants_fmt_updates, :boolean
  end

  def self.down
    remove_column :users, :wants_fmt_updates
  end
end
