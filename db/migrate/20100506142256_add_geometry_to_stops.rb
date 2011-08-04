class AddGeometryToStops < ActiveRecord::Migration
  def self.up
    add_column :stops, :coords, :point, :srid => 27700
    add_index :stops, :coords, :spatial => true
  end

  def self.down
    remove_index :stops, :coords
    remove_column :stops, :coords
  end
end
