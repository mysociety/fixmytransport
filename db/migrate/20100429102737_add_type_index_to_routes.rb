class AddTypeIndexToRoutes < ActiveRecord::Migration
  def self.up
    add_index :routes, :type
  end

  def self.down
    remove_index :routes, :type
  end
end
