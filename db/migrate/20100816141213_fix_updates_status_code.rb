class FixUpdatesStatusCode < ActiveRecord::Migration
  def self.up
    remove_column :updates, :status_code
    add_column :updates, :status_code, :integer
  end

  def self.down
    remove_column :updates, :status_code
    add_column :updates, :status_code, :boolean
  end
end
