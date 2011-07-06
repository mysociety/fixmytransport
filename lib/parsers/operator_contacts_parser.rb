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
  
  def normalize_address(address)
    address.gsub("\n", ', ').split(" ").join(" ").gsub(",,", ',').gsub(" ,", ',').chomp(',')
  end
  
  def clean_field(value)
    if !value.blank?
      value.strip!
    end
    value
  end
  
  def parse_operator_contacts(filepath, dryrun=false)
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      data = {}
      data[:id] = row['ID']
      data[:operator] = row['Operator name']
      data[:email] = row['Contact email']
      data[:phone] = row['Phone number']
      data[:company_no] = row['Registered company no']
      data[:registered_address] = row["Registered address"]
      data[:notes] = row['Notes']
      data[:url] = row['Company URL']
      data[:contact_category] = row['Contact category']
      data[:contact_location] = row['Contact location']
            
      id = data[:id].to_i
      name = data[:operator].strip
      operator_fields = [:phone, :company_no, :registered_address, :notes, :url]
      contact_fields = [:email, :contact_category, :contact_location]

      if id != 0
        operator = Operator.find(id)
        if operator.name != name
          puts "Name mismatch for id #{id}: #{name} vs. #{operator.name}" if dryrun
        else
          
          operator_fields.each do |operator_field|
            existing_value = operator.send(operator_field)
            new_value = data[operator_field]
            new_value = nil if new_value == '???'
            if operator_field == :registered_address && !new_value.blank?
              new_value = normalize_address(new_value)
            end
            new_value = clean_field(new_value)
            if existing_value.blank? && !new_value.blank?
              if dryrun
                puts "#{id} #{operator_field} new value #{new_value}" 
              else 
                operator.send("#{operator_field}=", new_value)
              end
            elsif (!existing_value.blank?) && (!new_value.blank?) && existing_value != new_value
              if dryrun
                puts "Conflict #{id} #{operator_field}: was #{existing_value} now #{new_value}" 
              else
                operator.send("#{operator_field}=", new_value)
              end
            end
          end
          email = clean_field(data[:email])
          category = clean_field(data[:contact_category])
          if category.blank?
            category = 'Other'
          end
          if operator.operator_contacts.empty?
            if dryrun
              puts "new contact for #{operator.name}: #{email} #{category}" 
            else
              contact = operator.operator_contacts.build(:email => email, :category => category, :deleted => false)            
            end
          else
            matches = operator.operator_contacts.select{ |contact| contact.email == email && contact.category == category }
            
            if matches.empty?
              if dryrun
                existing_info = operator.operator_contacts.map{|contact| [contact.email, contact.category]}
                puts "new contact for #{operator.name}: #{email} #{category} existing #{existing_info.inspect}"
              else
                contact = operator.operator_contacts.build(:email => email, :category => category, :deleted => false)            
              end
            end
          end
          
        end
      else
        if dryrun
          puts "New record? #{name}"
        end
      end
      if block_given?
        yield operator
      end
    end
  end

end