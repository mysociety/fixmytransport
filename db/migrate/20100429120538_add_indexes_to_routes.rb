class AddIndexesToRoutes < ActiveRecord::Migration
  def self.up
    add_index :routes, :number
    add_index :routes, :transport_mode_id
  end

  def self.down
    remove_index :routes, :number
    remove_index :routes, :transport_mode_id
  end
end
