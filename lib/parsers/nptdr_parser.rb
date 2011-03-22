require 'fastercsv'
class Parsers::NptdrParser

  def initialize
  end

  def csv_options
    { :quote_char => '"',
      :col_sep => "\t",
      :row_sep =>:auto,
      :return_headers => false,
      :headers => :first_row,
      :encoding => 'U' }
  end

  def vehicle_codes_to_transport_modes(vehicle_code)
    codes_to_modes = {'T' => 'Train',
                      'B' => 'Bus',
                      'C' => 'Coach',
                      'M' => 'Tram/Metro',
                      'A' => 'Air',
                      'F' => 'Ferry'}
    transport_mode_name = codes_to_modes[vehicle_code]
    if ! transport_mode_name
      raise "Unknown vehicle code '#{vehicle_code}'"
    end
    return TransportMode.find_by_name(transport_mode_name)
  end

  def parse_stops filepath
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      gazetteer_code = row['Gazeteer Code']
      gazetteer_id = row['National Gazetteer ID']
      district_name = row['District Name']
      town_name = row['Town Name']
      if !gazetteer_code.blank?
        locality = Locality.find_by_code(gazetteer_code)
      else
        locality = nil
      end
      yield Stop.new(:atco_code => row['Location Code'],
                     :common_name => row['Name'],
                     :easting => row['Easting'],
                     :northing => row['Northing'],
                     :locality => locality
                     )
    end
  end

  def region_from_filepath(filepath)
    admin_area = self.admin_area_from_filepath(filepath)
    if admin_area == :national
      region = Region.find(:first, :conditions => ['name = ?', 'Great Britain'])
    else
      region = admin_area.region
    end
    region
  end

  def admin_area_from_filepath(filepath)
    filename = File.basename(filepath, '.tsv')
    admin_area_code = filename.split('_').last
    if admin_area_code == 'National'
      admin_area = :national
    else
      admin_area = AdminArea.find_by_atco_code(admin_area_code)
    end
    admin_area
  end


  def mark_stop_code_missing(missing_stops, stop_code, route)
    if ! missing_stops[stop_code]
      missing_stops[stop_code] = []
    end
    route_string = "#{route.type} #{route.number}"
    if ! missing_stops[stop_code].include?(route_string)
      missing_stops[stop_code] << route_string
    end
    return missing_stops
  end

  def parse_routes filepath
    csv_data = File.read(filepath)
    admin_area = self.admin_area_from_filepath(filepath)
    region = self.region_from_filepath(filepath)
    missing_stops = {}

    FasterCSV.parse(csv_data, csv_options) do |row|
      route_number = row['Route Number']
      vehicle_code = row['Vehicle Code']
      operator_code = row['Operator Code']
      route_number.strip! if route_number
      vehicle_code.strip! if vehicle_code
      operator_code.strip! if operator_code
      stop_codes = row['Locations'].split(',')
      transport_mode = vehicle_codes_to_transport_modes(vehicle_code)
      next unless transport_mode.route_type
      route_type = transport_mode.route_type.constantize
      route = route_type.new(:number => route_number,
                             :transport_mode => transport_mode,
                             :region => region,
                             :operator_code => operator_code)
      if admin_area == :national
        source_admin_area = nil
      else
        source_admin_area = admin_area
      end
      route.route_source_admin_areas.build({:source_admin_area => source_admin_area,
                                            :operator_code => operator_code})

      operators = Operator.find_all_by_nptdr_code(transport_mode, operator_code, region, route)
      operators.each do |operator|
        route.route_operators.build({ :operator => operator })
      end
      # Which ones are in the db
      options = {:includes => {:stop_area_memberships => :stop_area}}
      found, missing = stop_codes.partition{ |stop_code| Stop.find_by_code(stop_code.strip, options) }

      missing.each do |missing_stop_code|
        missing_stops = self.mark_stop_code_missing(missing_stops, missing_stop_code, route)
      end
      jp = route.journey_patterns.build()
      segment_order = 0
      found.each_cons(2) do |from_stop_code,to_stop_code|
        from_stop = Stop.find_by_code(from_stop_code.strip, options)
        to_stop = Stop.find_by_code(to_stop_code.strip, options)
        route_segment = jp.route_segments.build(:from_stop => from_stop,
                                                :to_stop   => to_stop,
                                                :route => route,
                                                :segment_order => segment_order,
                                                :from_terminus => false,
                                                :to_terminus  => false)
        segment_order += 1
        route_segment.set_stop_areas
      end
      if jp.route_segments.size > 0
        jp.route_segments.first.from_terminus = true
        jp.route_segments.last.to_terminus = true
      end
      yield route
    end
    return missing_stops
  end

end