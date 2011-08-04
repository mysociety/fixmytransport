class AddCoordsToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :coords, :point, :srid => 27700
    add_index :routes, :coords, :spatial => true
  end

  def self.down
    remove_index :routes, :coords
    remove_column :routes, :coords
  end
end
