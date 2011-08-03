class AddCoordsToRoutes < ActiveRecord::Migration
  def self.up
    spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
    if spatial_extensions
      add_column :routes, :coords, :point, :srid => 27700
      add_index :routes, :coords, :spatial => true
    end
  end

  def self.down
    spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
    if spatial_extensions
      remove_index :routes, :coords
      remove_column :routes, :coords
    end
  end
end
