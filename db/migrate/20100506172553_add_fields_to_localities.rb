class AddFieldsToLocalities < ActiveRecord::Migration
  def self.up
    add_column :localities, :qualifier_locality, :string
    add_column :localities, :qualifier_district, :string
    add_column :localities, :qualifier_name, :string
    add_column :localities, :source_locality_type, :string
    add_column :localities, :grid_type, :string
    add_column :localities, :northing, :float
    add_column :localities, :easting, :float
    spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
    if spatial_extensions
      add_column :localities, :coords, :point, :srid => 27700
      add_index :localities, :coords, :spatial => true
    end
  end

  def self.down
    remove_column :localities, :qualifier_name
    remove_column :localities, :qualifier_district
    remove_column :localities, :qualifier_locality
    remove_column :localities, :source_locality_type
    remove_column :localities, :coords
    remove_column :localities, :easting
    remove_column :localities, :northing
    remove_column :localities, :grid_type
    spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
    if spatial_extensions
      remove_index :localities, :coords
      remove_column :localities, :coords
    end
  end
end
