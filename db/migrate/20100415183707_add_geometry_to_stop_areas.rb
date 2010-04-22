class AddGeometryToStopAreas < ActiveRecord::Migration
  def self.up
    spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
    if spatial_extensions
      add_column :stop_areas, :coords, :point, :srid => 27700
      add_index :stop_areas, :coords, :spatial => true
    end
  end

  def self.down
    spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
    if spatial_extensions
      remove_index :stop_areas, :coords
      remove_column :stop_areas, :coords
    end
  end
end
