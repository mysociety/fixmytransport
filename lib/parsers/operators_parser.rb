# Parser for loading operator data for stops by CRS code

class Parsers::OperatorsParser 

  def initialize
  end
  
  # Loads data from a file with tab-separated columns for CRS code, name, an unused field, and operator name
  # Loads name mappings from a file with tab-separated columns for alternative versions of names
  def match_operators(filepath, mapping_file)
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
        puts "*** Couldn't find stop for #{name} #{crs_code} ***"
        next
      end
      operators = Operator.find(:all, :conditions => ['LOWER(name) = ?', operator_name.downcase])
      if operators.empty? and operator_mappings[operator_name]
        operator_name = operator_mappings[operator_name]
        operators = Operator.find(:all, :conditions => ['LOWER(name) = ?', operator_name.downcase])
      end
      raise "No operator #{operator_name}" if operators.empty?
      raise "Multiple operators #{operator_name}" if operators.size > 1
      operator = operators.first
      stop.stop_operators.create(:operator => operator)
      puts "#{stop.common_name} #{operator.name}"
    end
  end
end