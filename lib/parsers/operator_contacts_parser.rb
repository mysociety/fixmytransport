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
      if contact_fields.any?{ |field| ! data[field].blank? }
        operators = Operator.find(:all, :conditions => ['name = ?', data[:operator]])
        if operators.size == 1
          operator = operators.first
          begin
            contact = operator.operator_contacts.create!(:email => data[:email], 
                                                         :category => 'Other', 
                                                         :notes => data[:notes])
          rescue 
            puts "Unable to add contact #{data[:email]} for #{data[:operator]}"
          end
        elsif operators.size > 1
          puts "multiple matches #{data[:operator]} / #{operators.map{|op| op.name}.join(" ")}"
        end
      end
    end
  end

end