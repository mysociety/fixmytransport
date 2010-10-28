class AddLatAndLonToLocalities < ActiveRecord::Migration
  def self.up
    add_column :localities, :lat, :float
    add_column :localities, :lon, :float
  end

  def self.down
    remove_column :localities, :lon
    remove_column :localities, :lat
  end
end
