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
    if vehicle_code == 'T'
      transport_mode_name = 'Train'
    elsif vehicle_code == 'B'
      transport_mode_name = 'Bus'
    elsif vehicle_code == 'C'
      transport_mode_name = 'Coach'
    elsif vehicle_code == 'M'
      transport_mode_name = 'Tram/Metro'
    elsif vehicle_code == 'A'
      transport_mode_name = 'Air'
    elsif vehicle_code == 'F'
      transport_mode_name = 'Ferry'
    else
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
    region = admin_area.region
  end
  
  def admin_area_from_filepath(filepath)
    filename = File.basename(filepath, '.tsv')
    admin_area_code = filename.split('_').last
    admin_area = AdminArea.find_by_atco_code(admin_area_code)  
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
                             :operator_code => operator_code,
                             :source_admin_area => admin_area)         
      # If the code is unambiguous for the region, add the operator
      operator_codes = OperatorCode.find_all_by_code_and_region_id(operator_code, region)
      operator_codes.each do |op_code|
        route.route_operators.build({:operator => op_code.operator})
      end
      if operator_codes.size == 0
        # Is it an ATOC train code? 
        if transport_mode.name == 'Train' and operator_code.size == 2
          operators = Operator.find_all_by_noc_code("=#{operator_code}")
          operators.each do |oper|
            route.route_operators.build({:operator => oper})
          end
        end
      end
      stop_codes.each_cons(2) do |from_stop_code,to_stop_code|
        options = {:includes => {:stop_area_memberships => :stop_area}}
        from_stop = Stop.find_by_code(from_stop_code.strip, options)
        to_stop = Stop.find_by_code(to_stop_code.strip, options)
        if ! from_stop
          if ! missing_stops[from_stop_code]
            missing_stops[from_stop_code] = []
          end
          route_string = "#{route.type} #{route.number}"
          if ! missing_stops[from_stop_code].include?(route_string)
            missing_stops[from_stop_code] << route_string
          end
          # puts "Can't find stop #{from_stop_code} for route #{route.inspect}" 
          next
        end
        if ! to_stop
          if ! missing_stops[to_stop_code]
            missing_stops[to_stop_code] = []
          end
          route_string = "#{route.type} #{route.number}"
          if ! missing_stops[to_stop_code].include?(route_string)
            missing_stops[to_stop_code] << route_string
          end
          # puts "Can't find stop #{to_stop_code} for route #{route.inspect}"
          next
        end
        if (from_stop.atco_code == stop_codes.first) or (from_stop.other_code == stop_codes.first) 
          from_terminus = true
        else
          from_terminus = false
        end
        if (to_stop.atco_code == stop_codes.last) or (to_stop.other_code == stop_codes.last)
          to_terminus = true
        else
          to_terminus = false
        end
        route.route_segments.build(:from_stop => from_stop, 
                                   :to_stop   => to_stop,
                                   :from_terminus => from_terminus, 
                                   :to_terminus  => to_terminus)
      end               
      
      yield route
    end
    return missing_stops
  end

end