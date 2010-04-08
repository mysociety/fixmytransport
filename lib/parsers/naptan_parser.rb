require 'fastercsv'
require 'iconv'

class Parsers::NaptanParser 

  def initialize
  end
  
  def parse_stops filepath
    stops = []
    csv_options = { :quote_char => '"', 
                    :col_sep =>',', 
                    :row_sep =>:auto, 
                    :return_headers => false,
                    :headers => :first_row,
                    :encoding => 'N' }
    csv_data = Iconv.iconv('utf-8', 'ISO_8859-1', File.read(filepath)).join
    FasterCSV.parse(csv_data, csv_options) do |row|
      yield Stop.new( :atco_code                  => row['AtcoCode'],
                      :naptan_code                => row['NaptanCode'],
                      :plate_code                 => row['PlateCode'], 
                      :common_name                => row['CommonName'], 
                      :common_name_lang           => row['CommonNameLang'], 
                      :short_common_name          => row['ShortCommonName'], 
                      :short_common_name_lang     => row['ShortCommonNameLang'],
                      :landmark                   => row['Landmark'], 
                      :landmark_lang              => row['LandmarkLang'], 
                      :street                     => row['Street'],
                      :street_lang                => row['StreetLang'], 
                      :crossing                   => row['Crossing'], 
                      :crossing_lang              => row['CrossingLang'], 
                      :indicator                  => row['Indicator'], 
                      :indicator_lang             => row['IndicatorLang'], 
                      :bearing                    => row['Bearing'], 
                      :nptg_locality_code         => row['NptgLocalityCode'],
                      :locality_name              => row['LocalityName'],
                      :parent_locality_name       => row['ParentLocalityName'],
                      :grand_parent_locality_name => row['GrandParentLocalityName'],
                      :town                       => row['Town'],
                      :town_lang                  => row['TownLang'],
                      :suburb                     => row['Suburb'],
                      :suburb_lang                => row['SuburbLang'],
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