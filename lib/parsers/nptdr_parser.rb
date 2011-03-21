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

  def convert_encoding filepath
    Iconv.iconv('utf-8', 'WINDOWS-1252', File.read(filepath)).join
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


  # existing_operator and new_operator are arrays of [short_name, legal_name]
  # can merge if they have the same non-blank shortname and one has a blank
  # legal name
  def can_merge?(existing_operator, new_operator)
    if !existing_operator[:short_form] or !new_operator[:short_form]
      return false
    end
    if (existing_operator[:short_form] != new_operator[:short_form])
      return false
    end
    if (!existing_operator[:legal_name].blank? and !new_operator[:legal_name].blank?)
      return false
    end
    return true
  end

  def merge_operators(existing_operators, new_operator)
    merged = false
    existing_operators.each do |existing_operator|
      if can_merge?(existing_operator, new_operator)
        if existing_operator[:legal_name].blank?
          existing_operator[:legal_name] = new_operator[:legal_name]
        end
        merged = true
      end
    end
    return merged
  end

  def preprocess_operators filepath
    csv_data = convert_encoding(filepath)
    operators_by_code = {}
    FasterCSV.parse(csv_data, csv_options) do |row|
      code = row['Operator'].strip
      short_form = row['Operator Short Form'].strip
      legal_name = row['Operator Legal Name'].strip
      operator_info = { :short_form => short_form, :legal_name => legal_name }
      if operators_by_code[code].nil?
        operators_by_code[code] = []
      end
      if operators_by_code[code].empty?
        operators_by_code[code] << operator_info
      else
        if !operators_by_code[code].include? operator_info
          merged = merge_operators(operators_by_code[code], operator_info)
          if !merged
            operators_by_code[code] << operator_info
          end
        end
      end
    end
    write_operator_file(operators_by_code, filepath)
  end

  def write_operator_file(operators_by_code, filepath)
    unique_outfile_path = "#{filepath}.unique"
    num_total = 0
    header_line = ["Code", "Short Name", "Name"].join("\t") + "\n"
    File.open(unique_outfile_path, 'w') do |unique|
      unique.write(header_line)
      operators_by_code.each do |key, operators|
        operators.each do |operator|
          line = ([key] + [operator[:short_form], operator[:legal_name]]).join("\t") + "\n"
          unique.write(line)
          num_total += 1
        end
      end
      puts "Created #{num_total} rows"
    end
  end

  def parse_operators(filepath)
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      short_name = row['Short Name']
      name = row['Name']
      short_name = short_name.strip if short_name
      name = name.strip if name
      if name.blank? and !short_name.blank?
        name = short_name
      end
      if short_name.blank? and !name.blank?
        short_name = name
      end
      yield Operator.new(:code       => row['Code'].strip,
                         :short_name => short_name,
                         :name       => name)
    end
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
      region = Region.find_by_name(:first, 'Great Britain')
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
      jp.route_segments.first.from_terminus = true
      jp.route_segments.last.to_terminus = true
      yield route
    end
    return missing_stops
  end

end