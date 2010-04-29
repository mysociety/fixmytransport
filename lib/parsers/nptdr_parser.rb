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
      transport_mode_name = 'Metro'
    elsif vehicle_code == 'A'
      transport_mode_name = 'Air'
    elsif vehicle_code == 'F'
      transport_mode_name = 'Ferry'
    else
      raise "Unknown vehicle code '#{vehicle_code}'"
    end
    return TransportMode.find_by_name(transport_mode_name)
  end
  
  def parse_operators filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      yield Operator.new(:code       => row['Operator'].strip, 
                         :name       => row['Operator Legal Name'].strip,
                         :short_name => row['Operator Short Form'].strip)
    end
  end
  
  def parse_stops filepath
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      yield Stop.new(:atco_code => row['Location Code'],
                     :common_name => row['Name'], 
                     :easting => row['Easting'], 
                     :northing => row['Northing'])
    end
  end
  
  def parse_routes filepath
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      route_number = row['Route Number'].strip
      vehicle_code = row['Vehicle Code'].strip
      operator_code = row['Operator Code'].strip      
      stop_codes = row['Locations'].split(',')
      transport_mode = vehicle_codes_to_transport_modes(vehicle_code)
      next unless transport_mode.route_type
      route_type = transport_mode.route_type.constantize
      route = route_type.new(:number => route_number,
                             :transport_mode => transport_mode)                 
      stop_codes.each_with_index do |stop_code,index|
        stop = Stop.find_by_atco_code(stop_code.strip)
        if ! stop
          puts "Can't find stop #{stop_code} for route #{route.inspect}" 
          next
        end
        if index == 0 or (index == stop_codes.size - 1)
          terminus = true
        else
          terminus = false
        end
        route.route_stops.build(:stop => stop, :terminus => terminus)
      end
      operator = Operator.find_or_create_by_code(operator_code)   
      route.route_operators.build(:operator => operator)                  
      yield route
    end
  end

end