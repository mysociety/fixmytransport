class AddStatusToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :status, :string
  end

  def self.down
    remove_column :routes, :status
  end
end
