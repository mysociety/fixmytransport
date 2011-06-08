class AddCachedDescriptionToStopsAndStopAreas < ActiveRecord::Migration
  def self.up
    add_column :stops, :cached_description, :string
    add_column :stop_areas, :cached_description, :string
  end

  def self.down
    remove_column :stop_areas, :cached_description
    remove_column :stops, :cached_description
  end
end
