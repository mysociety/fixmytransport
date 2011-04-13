# Parser for loading operator data for stops by CRS code

class Parsers::OperatorsParser 

  def initialize
  end
  
  # Loads data from a file with tab-separated columns for CRS code, name, an unused field, and operator name
  # Loads name mappings from a file with tab-separated columns for alternative versions of names
  def parse_station_operators(filepath, mapping_file="data/operators/operator_mappings.txt", stop_area_type='GRLS')
    operator_mappings = {}
    File.open(mapping_file).each_with_index do |line, index|
      next if index == 0
      row_data = line.strip.split("\t")
      operator_mappings[row_data[0]] = row_data[1]
    end
    File.open(filepath).each_with_index do |line, index|
      next if index == 0
      row_data = line.strip.split("\t")
      crs_code = row_data[0]
      name = row_data[1]
      operator_name = row_data[3]
      stop = Stop.find_by_crs_code(crs_code)
      if ! stop
        puts "*** Couldn't find stop for #{name} #{crs_code} #{operator_name}***"
        next
      end
      operators = Operator.find(:all, :conditions => ['LOWER(name) = ?', operator_name.downcase])
      if operators.empty? and operator_mappings[operator_name]
        operator_name = operator_mappings[operator_name]
        # puts "using mapping for #{operator_name}"
        operators = Operator.find(:all, :conditions => ['LOWER(name) = ?', operator_name.downcase])
      end
      raise "No operator #{operator_name}" if operators.empty?
      raise "Multiple operators #{operator_name}" if operators.size > 1
      operator = operators.first
      stop_area = stop.root_stop_area(stop_area_type)
      if ! stop_area
        puts "No stop_area for stop #{stop.name} #{operator_name}"
        next
      end
      stop_area_operator = stop_area.stop_area_operators.build(:operator => operator)
      yield stop_area_operator
      # puts "#{stop_area.name} #{operator.name}"
    end
  end
end