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
  
  def parse_stop_types filepath
    csv_options = self.csv_options.merge(:encoding => 'U')
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      yield StopType.new(:code        => row['Value'], 
                         :description => row['Description'], 
                         :on_street   => row['On Street'] == 'On street' ? true : false, 
                         :mode        => row['Mode'], 
                         :point_type  => row['Type'], 
                         :version     => row['Version'])
    end
  end
  
  def parse_stop_area_memberships filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      stops = Stop.find(:all, :conditions => ["lower(atco_code) = ?", row['AtcoCode'].downcase])
      raise "Atco code #{row['AtcoCode']} - #{stops.size} stops found" if stops.size != 1
      stop_areas = StopArea.find(:all, :conditions => ["lower(code) = ?", row['StopAreaCode'].downcase])
      raise "Area code #{row['StopAreaCode']} - #{stop_areas.size} stop areas found" if stop_areas.size != 1
      yield StopAreaMembership.new( :stop_id                => stops.first.id,
                                    :stop_area_id           => stop_areas.first.id,
                                    :creation_datetime      => row['CreationDateTime'],
                                    :modification_datetime  => row['ModificationDateTime'],
                                    :revision_number        => row['RevisionNumber'],
                                    :modification           => row['Modification'])
    end
  end
  
  def parse_stop_areas filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      yield StopArea.new( :code                      => row['StopAreaCode'],
                          :name                      => row['Name'],
                          :administrative_area_code  => row['AdministrativeAreaCode'], 
                          :area_type                 => row['StopAreaType'], 
                          :grid_type                 => row['GridType'], 
                          :easting                   => row['Easting'],
                          :northing                  => row['Northing'],
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