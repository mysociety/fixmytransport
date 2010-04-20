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
    if vehicle_code == 'T'
      return "train"
    elif vehicle_code == 'B'
      return "bus"
    elif vehicle_code == 'C'
      return "coach"
    elif vehicle_code == 'M'
      return "metro"
    elif vehicle_code == 'A'
      return "air"
    elif vehicle_code == 'F'
      return "ferry"
    else
      raise "Unknown vehicle code"
    end
  end
  
  def parse_routes filepath
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      vehicle_code = row['Vehicle Code']
      operator_code = row['Operator Code']
      stop_codes = row['Locations'].split(',')
      yield Route.new(:number => row['Route Number'].strip)
    end
  end

end