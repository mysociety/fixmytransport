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
  
  def parse_operators filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      transport_mode_name = row['Transport Mode']
      transport_mode = TransportMode.find_by_name(transport_mode_name)
      yield Operator.new(:code       => row['Operator Code'].strip, 
                         :name       => row['Operator Name'].strip)
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
                             :transport_mode => transport_mode)         
      stop_codes.each_cons(2) do |from_stop_code,to_stop_code|
        options = {:includes => {:stop_area_memberships => :stop_area}}
        from_stop = Stop.find_by_atco_code(from_stop_code.strip, options)
        to_stop = Stop.find_by_atco_code(to_stop_code.strip, options)
        if ! from_stop
          puts "Can't find stop #{from_stop_code} for route #{route.inspect}" 
          next
        end
        if ! to_stop
          puts "Can't find stop #{to_stop_code} for route #{route.inspect}"
          next
        end
        if from_stop.atco_code == stop_codes.first 
          from_terminus = true
        else
          from_terminus = false
        end
        if to_stop.atco_code == stop_codes.last
          to_terminus = true
        else
          to_terminus = false
        end
        route.route_segments.build(:from_stop => from_stop, 
                                   :to_stop   => to_stop,
                                   :from_terminus => from_terminus, 
                                   :to_terminus  => to_terminus)
      end
      operator = Operator.find_or_create_by_code(operator_code)   
      route.route_operators.build(:operator => operator)                  
      yield route
    end
  end

end