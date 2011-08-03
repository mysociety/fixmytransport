class AddCoordsToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :lat, :float
    add_column :problems, :lon, :float
    add_column :problems, :coords, :point, :srid => 27700
    add_index :problems, :coords, :spatial => true
  end

  def self.down
    remove_column :problems, :coords
    remove_column :problems, :lat
    remove_column :problems, :lon
  end
end
