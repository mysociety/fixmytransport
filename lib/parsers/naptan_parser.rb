require 'fastercsv'
require 'iconv'

class Parsers::NaptanParser 

  def initialize
  end
  
  def csv_options
    { :quote_char => '"', 
      :col_sep =>',', 
      :row_sep =>:auto, 
      :return_headers => false,
      :headers => :first_row,
      :encoding => 'N' }
  end
  
  def convert_encoding filepath
    Iconv.iconv('utf-8', 'ISO_8859-1', File.read(filepath)).join
  end
  
  def parse_stop_area_hierarchy filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      ancestor = StopArea.find_by_code(row['ParentStopAreaCode'])
      descendant = StopArea.find_by_code(row['ChildStopAreaCode'])
      yield StopAreaLink.build_edge(ancestor, descendant)
    end
  end
  
  def parse_stop_types filepath
    csv_options = self.csv_options.merge(:encoding => 'U')
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      stop_type = StopType.new(:code              => row['Value'], 
                               :description       => row['Description'], 
                               :on_street         => row['On Street'] == 'On street' ? true : false, 
                               :point_type        => row['Type'], 
                               :version           => row['Version'])                   
      transport_mode_names = row['Mode'].split(',')
      transport_mode_names.each do |transport_mode_name|
        transport_mode = TransportMode.find_by_naptan_name(transport_mode_name)
        stop_type.transport_mode_stop_types.build(:transport_mode_id => transport_mode.id)
      end
      yield stop_type
    end
  end
  
  def parse_stop_area_memberships filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      stop = Stop.find_by_atco_code(row['AtcoCode'])
      stop_area = StopArea.find_by_code(row['StopAreaCode'])
      yield StopAreaMembership.new( :stop_id                => stop.id,
                                    :stop_area_id           => stop_area.id,
                                    :creation_datetime      => row['CreationDateTime'],
                                    :modification_datetime  => row['ModificationDateTime'],
                                    :revision_number        => row['RevisionNumber'],
                                    :modification           => row['Modification'])
    end
  end
  
  def parse_stop_areas filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
      if spatial_extensions
        coords = Point.from_x_y(row['Easting'], row['Northing'], WGS_84)
      else
        coords = nil
      end
      yield StopArea.new( :code                      => row['StopAreaCode'],
                          :name                      => row['Name'],
                          :administrative_area_code  => row['AdministrativeAreaCode'], 
                          :area_type                 => row['StopAreaType'], 
                          :grid_type                 => row['GridType'], 
                          :easting                   => row['Easting'],
                          :northing                  => row['Northing'],
                          :coords                    => coords,
                          :creation_datetime         => row['CreationDateTime'],
                          :modification_datetime     => row['ModificationDateTime'],
                          :revision_number           => row['RevisionNumber'],
                          :modification              => row['Modification'],
                          :status                    => row['Status'])
    end
  end
  
  def parse_stops filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      yield Stop.new( :atco_code                  => row['AtcoCode'],
                      :naptan_code                => row['NaptanCode'],
                      :plate_code                 => row['PlateCode'], 
                      :common_name                => row['CommonName'], 
                      :short_common_name          => row['ShortCommonName'], 
                      :landmark                   => row['Landmark'], 
                      :street                     => row['Street'],
                      :crossing                   => row['Crossing'], 
                      :indicator                  => row['Indicator'], 
                      :bearing                    => row['Bearing'], 
                      :nptg_locality_code         => row['NptgLocalityCode'],
                      :locality_name              => row['LocalityName'],
                      :parent_locality_name       => row['ParentLocalityName'],
                      :grand_parent_locality_name => row['GrandParentLocalityName'],
                      :town                       => row['Town'],
                      :suburb                     => row['Suburb'],
                      :locality_centre            => row['LocalityCentre'],
                      :grid_type                  => row['GridType'],
                      :easting                    => row['Easting'],
                      :northing                   => row['Northing'],
                      :lon                        => row['Longitude'],
                      :lat                        => row['Latitude'],
                      :stop_type                  => row['StopType'],
                      :bus_stop_type              => row['BusStopType'],
                      :administrative_area_code   => row['AdministrativeAreaCode'],
                      :creation_datetime          => row['CreationDateTime'],
                      :modification_datetime      => row['ModificationDateTime'],
                      :revision_number            => row['RevisionNumber'],
                      :modification               => row['Modification'],
                      :status                     => row['Status'])
    end
  end

end