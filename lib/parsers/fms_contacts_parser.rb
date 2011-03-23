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
      next if row['category'].blank?
      confirmed = !row['confirmed'].nil?
      if row['area_id'] == '2225' and row['email'].strip == 'SPECIAL'
        district_mappings = { 'eastarea' => [2315, 2312],
                              'midarea' => [2317, 2314, 2316],
                              'southarea' => [2319, 2320, 2310],
                              'westarea' => [2309, 2311, 2318, 2313] }
        district_mappings.each do |area_name, district_ids|
          district_ids.each do |district_id|
            yield CouncilContact.new({:area_id => row['area_id'],
                                      :email => "highways.#{area_name}@essexcc.gov.uk",
                                      :confirmed => confirmed,
                                      :district_id => district_id,
                                      :category => row['category'].strip,
                                      :notes => row['note']})
          end
        end
      else
        yield CouncilContact.new({:area_id => row['area_id'],
                                  :email => row['email'].strip,
                                  :confirmed => confirmed,
                                  :category => row['category'].strip,
                                  :notes => row['note']})
      end
    end
  end

end
