class AddFixedAndOpenFlagsToUpdates < ActiveRecord::Migration
  def self.up
    add_column :updates, :mark_fixed, :boolean
    add_column :updates, :mark_open, :boolean
  end

  def self.down
    remove_column :updates, :mark_open
    remove_column :updates, :mark_fixed
  end
end
