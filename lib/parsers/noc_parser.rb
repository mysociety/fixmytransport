require 'fastercsv'

class Parsers::NocParser

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

  def clean_operator_code(code)
    code = code.gsub(/\*|=/, '')
    code
  end

  def parse_operator_codes(filepath)
    region_codes = { "WA" => "W",
                     "YO" => "Y",
                     "SC" => "S",
                     "LO" => "L" }
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      next if row['VehicleMode'] == 'Airline'

      noc_code = row['NOCCODE'].strip
      operator = Operator.current.find_by_noc_code(noc_code)
      raise "Could not find operator with NOC code #{noc_code}" unless operator

      ["SW", "WM", "WA", "YO", "NW", "NE", "SC"].each do |region_code|
        if !row[region_code].blank?
          code = (region_codes[region_code] or region_code)
          region = Region.current.find_by_code(code)
          raise "Couldn't find region for #{code}" unless region
          yield OperatorCode.new(:code => clean_operator_code(row[region_code]),
                                 :region => region,
                                 :operator => operator)
        end
      end

      # Four regions (EA, EM, SE, LO) use the MDV system
      mdv_regions = ['EA', 'EM', 'SE', 'LO']
      if !row['MDV'].blank?
        mdv_code = row['MDV']
        mdv_regions.each do |region_code|
          region_code = (region_codes[region_code] or region_code)
          region = Region.current.find_by_code(region_code)
          raise "Couldn't find region for MDV region #{region_code}" unless region
          yield OperatorCode.new(:code => clean_operator_code(mdv_code),
                                 :region => region,
                                 :operator => operator)
        end
      end
    end
  end

  def parse_vosa_licenses(filepath)
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      next if row['VehicleMode'] == 'Airline'
      noc_code = row['NOCCODE'].strip
      operator = Operator.current.find_by_noc_code(noc_code)
      raise "Could not find operator with NOC code #{noc_code}" unless operator
        (1..8).each do |num|
        license_field = "VOSALicenceNo#{num}"
        if !row[license_field].blank?
          yield VosaLicense.new({:number => row[license_field],
                                 :operator => operator})
        end
      end
    end
  end

  def parse_operators(filepath)
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      next if row['VehicleMode'] == 'Airline'
      vehicle_mode = row['VehicleMode'] ? row['VehicleMode'] : 'Bus'
      transport_mode = Operator.vehicle_mode_to_transport_mode(vehicle_mode)
      # use license name if no name given
      name = row['OperatorPublicName'] ? row['OperatorPublicName'].strip : row['VOSA_PSVLicenseName'].strip
      reference_name = row['OperatorReferenceName '] ? row['OperatorReferenceName '].strip : nil
      vosa_license_name = row['VOSA_PSVLicenseName'] ? row['VOSA_PSVLicenseName'].strip : nil
      parent = row['Parent'] ? row['Parent'].strip : nil
      ultimate_parent = row['UltimateParent'] ? row['UltimateParent'].strip : nil
      operator = Operator.new(:noc_code => row['NOCCODE'].strip,
                              :name => name,
                              :reference_name => reference_name,
                              :vosa_license_name => vosa_license_name,
                              :parent => parent,
                              :ultimate_parent => ultimate_parent,
                              :vehicle_mode => vehicle_mode,
                              :transport_mode => transport_mode)
      yield operator
    end
  end

end