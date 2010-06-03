class AddNameToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :name, :string
  end

  def self.down
    remove_column :routes, :name
  end
end
