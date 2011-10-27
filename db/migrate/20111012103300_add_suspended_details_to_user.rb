class AddSuspendedDetailsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :suspended_reason, :text
    add_column :users, :suspended_hide_contribs, :boolean
  end

  def self.down
    remove_column :users, :suspended_reason
    remove_column :users, :suspended_hide_contribs
  end
end