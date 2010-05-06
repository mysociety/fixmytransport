class AddGeometryToStops < ActiveRecord::Migration
  def self.up
    spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
    if spatial_extensions
      add_column :stops, :coords, :point, :srid => 27700
      add_index :stops, :coords, :spatial => true
    end
  end

  def self.down
    spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
    if spatial_extensions
      remove_index :stops, :coords
      remove_column :stops, :coords
    end
  end
end
