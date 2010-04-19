class AddGeometryToStopAreas < ActiveRecord::Migration
  def self.up
    add_column :stop_areas, :coords, :point, :srid => 27700
    add_index :stop_areas, :coords, :spatial => true
  end

  def self.down
    remove_index :stop_areas, :coords
    remove_column :stop_areas, :coords
  end
end
