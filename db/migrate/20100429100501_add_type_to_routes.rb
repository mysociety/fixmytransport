class AddTypeToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :type, :string
  end

  def self.down
    remove_column :routes, :type
  end
end
