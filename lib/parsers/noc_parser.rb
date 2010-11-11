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
    code = code.gsub(Regexp.new('/*|=/'), '') 
    code
  end

  def parse_operators filepath
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      next if row['VehicleMode'] == 'Airline'
      
      noc_code = clean_operator_code(row['NOCCODE'])
      region_codes = { "WA" => "W", 
                       "YO" => "Y", 
                       "SC" => "S" }
      operator = Operator.new(:noc_code => row['NOCCODE'], 
                              :name => row['OperatorPublicName'], 
                              :reference_name => row['OperatorReferenceName '], 
                              :vosa_license_name => row['VOSA_PSVLicenseName'],
                              :parent => row['Parent'], 
                              :ultimate_parent => row['UltimateParent'], 
                              :vehicle_mode => row['VehicleMode'])
      
      ["SW", "WM", "WA", "YO", "NW", "NE", "SC"].each do |region_code|
        if !row[region_code].blank?
          code = (region_codes[region_code] or region_code)
          region = Region.find_by_code(code)
          raise "Couldn't find region for #{code}" unless region
          operator.operator_codes.build(:code => row[region_code], 
                                        :region => region)
        end
      end
      
      (1..8).each do |num|
        license_field = "VOSALicenceNo#{num}"
        if !row[license_field].blank?
          operator.vosa_licenses.build({:number => row[license_field]})
        end
      end
      
      yield operator
      
    end
  end

end