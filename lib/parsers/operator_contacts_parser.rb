class Parsers::OperatorContactsParser
  
  def initialize
  end
  
  def csv_options
    { :quote_char => '"',
      :col_sep => ",",
      :row_sep =>:auto,
      :return_headers => false,
      :headers => :first_row,
      :encoding => 'N' }
  end
  
  def parse_operator_contacts(filepath)
    csv_data = File.read(filepath)
    unmatched = 0
    matched = 0
    
    manual_matches = {"Anitas Coaches" => "Anita's Coaches", 
                      "Bakers" => nil, 
                      "BATH & NE SOMERSET COUNC" => "Bath & North East Somerset Council", 
                      "BELLE VUE MANCHESTER LTD" => "Belle Vue Coaches", 
                      "Blue Bus (Lancashire) Ltd" => "Blue Bus (Lancashire)", 
                      "Bostocks Coaches" => , 
                      "BU-VAL BUSES LIMITED" => "Bu-Val Buses", 
                      "BULLOCK TRANSPORT LTD" => "R Bullock Buses", 
                      "Burtons Coaches" => "Burtons Coaches", 
                      "Central Connect Ltd" => "Central Connect Ltd", 
                      "Centrebus Ltd Trading as Bowers Coaches" => nil, 
                      "Clarkes Coaches" => "Clarkes Coaches", 
                      "Compass Travel" => "Compass Travel (Sussex)", 
                      "D & G Coaches" => "D & G Coach & Bus", 
                      "De Courcey Travel" => "Mike De Courcey Travel", 
                      "East cYorkshire Motor Services" => "East Yorkshire Motor Services", 
                      "FINGLANDS SOUTH M/CR C'WAYS" => "Finglands",
                      "First Hampshire & Dorset" => "First in Hants & Dorset", 
                      "First Scotrail" => "ScotRail", 
                      "GHA Coaches" => nil, 
                      "Gorran & District Community Bus Association Ltd" => nil, 
                      "GOSPORT FERRY LTD" => nil, 
                      "GREATER M/CR BUSES SOUTH LTD" => nil, 
                      "Hull Trains" => nil, 
                      "J Durbin" => nil, 
                      "J.P. Minicoaches" => nil, 
                      "Keighley and District Travel Ltd" => nil, 
                      "London Central" => nil, 
                      "MERSEYSIDE TRANSPORT LTD." => nil, 
                      "Metrobus" => nil, 
                      "MR J M COX" => nil, 
                      "MR S LEWIS" => nil, 
                      "Muirs Coaches" => nil, 
                      "National Express West Midlands" => nil, 
                      "R. Kime & Co. Ltd." => nil, 
                      "Rackford Coaches" => nil, 
                      "RIBBLE MOTOR SERVICES LTD." => nil, 
                      "ROSSENDALE TRANSPORT LTD." => nil, 
                      "Scarborough and District Motor Services" => nil, 
                      "Scottish Citylink" => nil, 
                      "Southern" => nil, 
                      "Stagecoach" => nil, 
                      "Stagecoach Cambridgeshire" => nil, 
                      "STAGECOACH COASTLINE" => nil, 
                      "STAGECOACH DEVON" => nil, 
                      "Stagecoach East Midlands" => nil, 
                      "STAGECOACH IN WYE AND DE" => nil, 
                      "Stagecoach Manchester" => nil, 
                      "STAGECOACH MERSEYSIDE" => nil, 
                      "STAGECOACH MERSEYSIDE" => nil, 
                      "Stagecoach Sheffield" => nil, 
                      "Stagecoach Wye & Dean" => nil, 
                      "TM Travel" => nil, 
                      "Translink" => nil, 
                      "Travel Surrey" => nil, 
                      "Trent Barton" => nil, 
                      "WARR BORO" => nil, 
                      "Williams" => nil, 
                      "Wrexham + Shropshire" => nil }
    FasterCSV.parse(csv_data, csv_options) do |row|
      data = {}
      data[:operator] = row['Operator']
      data[:short_name] = row['Short name']
      data[:email] = row['Contact email for complaints (this is the most important data to collect!)']
      data[:company_no] = row['Company Number']
      data[:reg_address] = row["Company's Registered Postal Address"]
      data[:notes] = row['Notes/Observations of Interest']
      data[:url] = row['URL']
      all_fields = [:operator, :short_name, :email, :company_no, :reg_address, :notes, :url]
      contact_fields = [:email]
      operator = nil
      if contact_fields.any?{ |field| ! data[field].blank? } 
        name = data[:operator].blank? ? data[:short_name].strip : data[:operator].strip
        operators = Operator.find(:all, :conditions => ['lower(name) like ?
                                                         or lower(vosa_license_name) like ?', 
                                                         "#{name.downcase}%","#{name.downcase}%"])
        
        if operators.size == 1
          operator = operators.first   
          # puts "MATCH #{name}"       
        elsif operators.size == 0
          # partial_matches = Operator.find(:all, :conditions => ['lower(name) like ?', "#{name.downcase}%"])
          #        if partial_matches.size == 1
          #          operator = operators.first
          #        else
          #          name_without_ltd = name.gsub(/Ltd\.?/i, '').strip
          #          if name_without_ltd != name
          #            matches_without_ltd = Operator.find(:all, :conditions => ['lower(name) = ?', name_without_ltd.downcase])
          #            if matches_without_ltd.size == 1
          #              operator = matches_without_ltd.first
          #            end
          #          end
          #        end
        end
        if operator
           begin
             # contact = operator.operator_contacts.create!(:email => data[:email], 
                                                          # :category => 'Other', 
                                                          # :notes => data[:notes])
             matched += 1
           rescue 
             puts "Unable to add contact #{data[:email]} for #{data[:operator]}"
           end
        else
          puts "\"#{data[:operator]}\" => nil, "
          unmatched += 1
        end
      end

    end
    puts "unmatched #{unmatched}"
    puts "matched #{matched}"
  end

end