# Parser for loading FixMyStreet contacts data

class Parsers::FmsContactsParser 

  def csv_options
    { :quote_char => '"', 
      :col_sep => ",", 
      :row_sep =>:auto, 
      :return_headers => false,
      :headers => :first_row,
      :encoding => 'N' }
  end
  
  def parse_contacts filepath
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      next if row['deleted'] == 't'
      confirmed = !row['confirmed'].nil?
      yield CouncilContact.new({:area_id => row['area_id'], 
                                :email => row['email'], 
                                :confirmed => confirmed,
                                :category => row['category'],
                                :notes => row['note']})
    end
  end
  
end
