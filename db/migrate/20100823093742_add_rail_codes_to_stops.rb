class AddRailCodesToStops < ActiveRecord::Migration
  def self.up
    add_column :stops, :tiploc_code, :string
    add_column :stops, :crs_code, :string
  end

  def self.down
    remove_column :stops, :crs_code
    remove_column :stops, :tiploc_code
  end
end
