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

  def parse_rail_references filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      stop = Stop.find_by_atco_code((row['AtcoCode'] or row["NaPTAN"]))
      if ! stop
        puts "*** Missing #{row['AtcoCode']} ***"
        next
      end
      stop.tiploc_code = (row["TiplocCode"] or row["Tiploc Code"])
      stop.crs_code = (row["CrsCode"] or row["CRS Code"])
      # puts "#{stop.common_name} #{stop.tiploc_code} #{stop.crs_code}"
      yield stop
    end
  end

  def parse_stop_area_hierarchy filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      ancestor = StopArea.find_by_code((row['ParentStopAreaCode'] or row['ParentID']))
      descendant = StopArea.find_by_code((row['ChildStopAreaCode'] or row['ChildID']))
      if existing_link = StopAreaLink.find_link(ancestor, descendant)
        if ! StopAreaLink.direct?(ancestor, descendant)
          existing_link.make_direct()
          yield existing_link
        end
      else
        yield StopAreaLink.build_edge(ancestor, descendant)
      end
    end
  end

  def parse_stop_area_types filepath
    csv_options = self.csv_options.merge(:encoding => 'U',  :col_sep => "\t")
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      stop_area_type = StopAreaType.new(:code        => row['Value'],
                                        :description => row['Description'])
      transport_mode_names = row['Mode'].split(',')
      transport_mode_names.each do |transport_mode_name|
        transport_mode = TransportMode.find_by_naptan_name(transport_mode_name)
        stop_area_type.transport_mode_stop_area_types.build(:transport_mode_id => transport_mode.id)
      end
      yield stop_area_type
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
                               :sub_type          => row['SubType'].blank? ? nil : row['SubType'],
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
      stop = Stop.find_by_atco_code((row['AtcoCode'] or row['ATCOCode']))
      stop_area = StopArea.find_by_code((row['StopAreaCode'] or row['GroupID']))
      if stop and stop_area
        yield StopAreaMembership.new( :stop_id                => stop.id,
                                      :stop_area_id           => stop_area.id,
                                      :creation_datetime      => row['CreationDateTime'],
                                      :modification_datetime  => row['ModificationDateTime'],
                                      :revision_number        => row['RevisionNumber'],
                                      :modification           => row['Modification'])
      end
    end
  end

  def parse_stop_areas filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      coords = Point.from_x_y(row['Easting'], row['Northing'], BRITISH_NATIONAL_GRID)
      yield StopArea.new( :code                      => (row['StopAreaCode'] or row['GroupID']),
                          :name                      => (row['Name'] or row['GroupName']),
                          :administrative_area_code  => row['AdministrativeAreaCode'],
                          :area_type                 => (row['StopAreaType'] or row['Type']),
                          :grid_type                 => row['GridType'],
                          :easting                   => row['Easting'],
                          :northing                  => row['Northing'],
                          :coords                    => coords,
                          :lon                       => row['Lon'],
                          :lat                       => row['Lat'],
                          :creation_datetime         => row['CreationDateTime'],
                          :modification_datetime     => (row['ModificationDateTime'] or row['LastChanged']),
                          :revision_number           => row['RevisionNumber'],
                          :modification              => row['Modification'],
                          :status                    => row['Status'])
    end
  end

  def parse_stops filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      coords = Point.from_x_y(row['Easting'], row['Northing'], BRITISH_NATIONAL_GRID)
      locality = Locality.find_by_code((row['NptgLocalityCode'] or row['NatGazID']))
      yield Stop.new( :atco_code                  => (row['AtcoCode'] or row['ATCOCode']),
                      :naptan_code                => (row['NaptanCode'] or row['SMSNumber']),
                      :plate_code                 => clean_field(:plate_code, row['PlateCode']),
                      :common_name                => row['CommonName'],
                      :short_common_name          => row['ShortCommonName'],
                      :landmark                   => clean_field(:landmark, row['Landmark']),
                      :street                     => clean_field(:street, row['Street']),
                      :crossing                   => clean_field(:crossing, row['Crossing']),
                      :indicator                  => clean_field(:indicator, (row['Indicator'] or row['Identifier'])),
                      :bearing                    => (row['Bearing'] or row['Direction']),
                      :locality                   => locality,
                      :town                       => row['Town'],
                      :suburb                     => row['Suburb'],
                      :locality_centre            => row['LocalityCentre'],
                      :grid_type                  => row['GridType'],
                      :easting                    => row['Easting'],
                      :northing                   => row['Northing'],
                      :coords                     => coords,
                      :lon                        => (row['Longitude'] or row['Lon']),
                      :lat                        => (row['Latitude'] or row ['Lat']),
                      :stop_type                  => row['StopType'],
                      :bus_stop_type              => row['BusStopType'],
                      :administrative_area_code   => row['AdministrativeAreaCode'],
                      :creation_datetime          => row['CreationDateTime'],
                      :modification_datetime      => (row['ModificationDateTime'] or row['LastChanged']),
                      :revision_number            => row['RevisionNumber'],
                      :modification               => row['Modification'],
                      :status                     => (row['Status'] or row['RecordStatus']))
    end
  end

  def clean_field(field, value)
    null_value_indicators = { :landmark  => ['---', '*', 'Landmark not known', 'Unknown', 'N/A', '-', 'landmark','N', 'TBA', 'N/K', '-'],
                              :indicator => ['---'],
                              :crossing  => ['*', '--', 'No'],
                              :plate_code => [''],
                              :street    =>  ['---', '-', 'N/A', 'No name', 'Street not known', 'Unclassified', 'N/K', 'Unknown', 'Unnamed Road', 'Unclassified Road'],
                            }
    if value && null_value_indicators[field].include?(value.strip)
      return nil
    end
    return value
  end

end