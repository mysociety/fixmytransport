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
    manual_matches = {"Anitas Coaches" => "Anita's Coaches", 
                      "Bakers" => nil, 
                      "BATH & NE SOMERSET COUNC" => "Bath & North East Somerset Council", 
                      "BELLE VUE MANCHESTER LTD" => "Belle Vue Coaches", 
                      "Blue Bus (Lancashire) Ltd" => "Blue Bus (Lancashire)", 
                      "Bostocks Coaches" => nil, 
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
                      "GHA Coaches" => "G H A Coaches", 
                      "Gorran & District Community Bus Association Ltd" => "Gorran & District Community Bus", 
                      "GOSPORT FERRY LTD" => "Gosport Ferry", 
                      "GREATER M/CR BUSES SOUTH LTD" => "Stagecoach in Manchester", 
                      "Hull Trains" => "First Hull Trains", 
                      "J Durbin" => "South Gloucestershire Bus & Coach", 
                      "J.P. Minicoaches" => "J P Minicoaches", 
                      "Keighley and District Travel Ltd" => "Transdev Keighley & District Travel", 
                      "London Central" => "London Central", 
                      "MERSEYSIDE TRANSPORT LTD." => "Arriva Merseyside", 
                      "Metrobus" => "Metrobus", 
                      "MR J M COX" => "Checkmate Mini Coaches", 
                      "MR S LEWIS" => "Olympia Travel", 
                      "Muirs Coaches" => nil, 
                      "National Express West Midlands" => "West Midlands Travel", 
                      "R. Kime & Co. Ltd." => "Kimes", 
                      "Rackford Coaches" => nil, 
                      "RIBBLE MOTOR SERVICES LTD." => "Stagecoach in Lancashire", 
                      "ROSSENDALE TRANSPORT LTD." => "Rossendale Transport", 
                      "Scarborough and District Motor Services" => nil, 
                      "Scottish Citylink" => "Scottish Citylink", 
                      "Southern" => "Southern", 
                      "Stagecoach" => nil, 
                      "Stagecoach Cambridgeshire" => "Stagecoach in Cambridge", 
                      "STAGECOACH COASTLINE" => "Stagecoach in the South Downs", 
                      "STAGECOACH DEVON" => "Stagecoach South West", 
                      "Stagecoach East Midlands" => nil, 
                      "STAGECOACH IN WYE AND DE" => "Stagecoach in Wye & Dean", 
                      "Stagecoach Manchester" => "Stagecoach in Manchester", 
                      "STAGECOACH MERSEYSIDE" => "Stagecoach in Merseyside", 
                      "Stagecoach Sheffield" => "Stagecoach in Sheffield", 
                      "Stagecoach Wye & Dean" => "Stagecoach in Wye & Dean", 
                      "TM Travel" => "T M Travel Ltd", 
                      "Translink" => nil, 
                      "Travel Surrey" => "Abellio Surrey", 
                      "Trent Barton" => "Trent Barton", 
                      "WARR BORO" => "Warrington Borough Transport", 
                      "Williams" => "Williams", 
                      "Wrexham + Shropshire" => "Wrexham & Shropshire" }
    FasterCSV.parse(csv_data, csv_options) do |row|
      data = {}
      data[:operator] = row['Operator']
      data[:short_name] = row['Short name']
      data[:email] = row['Contact email for complaints (this is the most important data to collect!)']
      data[:company_no] = row['Company Number']
      data[:reg_address] = row["Company's Registered Postal Address"]
      data[:notes] = row['Notes/Observations of Interest']
      data[:url] = row['URL']
      if data[:notes] && /^https?:\/\/[^ ]+$/.match(data[:notes].strip)
        data[:url] = data[:notes].strip
        data[:notes] = nil
      end
      all_fields = [:operator, :short_name, :email, :company_no, :reg_address, :notes, :url]
      contact_fields = [:email]
      operator = nil
      if contact_fields.any?{ |field| ! data[field].blank? } 
        name = data[:operator].blank? ? data[:short_name].strip : data[:operator].strip
        if manual_matches[name]
          operators = Operator.find(:all, :conditions => ['name = ?', manual_matches[name]])
        else
          operators = Operator.find(:all, :conditions => ['lower(name) like ?
                                                          or lower(vosa_license_name) like ?', 
                                                          "#{name.downcase}%","#{name.downcase}%"])
        end
        if operators.size == 1
          operator = operators.first   
        end
        if operator
          operator.url = data[:url]
          operator.company_no = data[:company_no]
          if data[:reg_address]
            registered_address = data[:reg_address].strip.gsub("\n", ", ").gsub(" ,", ",").gsub(",,", ',')
            operator.registered_address = registered_address.chomp(",")
          end
          operator.notes = data[:notes]
          contact = operator.operator_contacts.build(:email => data[:email].strip, 
                                                     :category => 'Other')
          yield operator
        end
      end

    end
  end

end