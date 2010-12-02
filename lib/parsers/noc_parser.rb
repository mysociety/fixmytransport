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

  def parse_operators filepath
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      next if row['VehicleMode'] == 'Airline'
      
      region_codes = { "WA" => "W", 
                       "YO" => "Y", 
                       "SC" => "S", 
                       "LO" => "L" }
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
          operator.operator_codes.build(:code => clean_operator_code(row[region_code]), 
                                        :region => region)
        end
      end
      
      # Four regions (EA, EM, SE, LO) use the MDV system
      if !row['MDV'].blank?
        mdv_code = row['MDV']
        owner_region_code = row['TravelineOwner'].strip
        if ['EA', 'EM', 'SE', 'LO'].include?(owner_region_code)
          owner_region_code = (region_codes[owner_region_code] or owner_region_code)
          region = Region.find_by_code(owner_region_code)
          raise "Couldn't find region for Traveline Owner #{owner_region_code}" unless region
          operator.operator_codes.build(:code => clean_operator_code(mdv_code),
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