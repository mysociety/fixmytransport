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

  def traveline_csv_options
    { :quote_char => '"',
      :col_sep => "\t",
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

  def parse_traveline_operator_contacts(filepath, dryrun=false, options={})
    csv_data = File.read(filepath)
    FasterCSV.parse(csv_data, traveline_csv_options) do |row|
      data = {}
      data[:name] = clean_field(row['CompanyName'])
      data[:email] = clean_field(row['Email'])
      data[:phone] = []
      (1..6).each do |num|
        data[:phone] << clean_field(row["Telephone#{num}"])
      end
      data[:phone].compact!
      data[:phone] = data[:phone].join(", ")
      data[:registered_address] = []
      (1..7).each do |num|
        data[:registered_address] << clean_field(row["Address#{num}"])
      end
      data[:registered_address].compact!
      data[:registered_address] = data[:registered_address].join(", ")
      data[:url] = clean_field(row["Website"])
      data[:notes] = clean_field(row["GeneralInformation"])
      if data[:url] && data[:url].starts_with?('www')
        data[:url] = "http://#{data[:url]}"
      end
      if data[:url] && data[:url].starts_with?('sales@')
        data[:url] = nil
      end
      operators = Operator.find(:all, :conditions => ['name = ?', data[:name]])
      if operators.size == 1
        operator = operators.first
        if options[:new_contacts_only] == true
          load_new_contact_fields(dryrun, operator, data)
        else
          load_new_operator_fields(dryrun, operator, data)
          load_new_contact_fields(dryrun, operator, data)
        end
      end
    end
  end

  def load_new_operator_fields(dryrun, operator, data)
    operator_fields = [:phone, :company_no, :registered_address, :notes, :url]

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
          puts "#{operator.id} #{operator.name} #{operator_field} new value #{new_value}"
        else
          operator.send("#{operator_field}=", new_value)
        end
      elsif (!existing_value.blank?) && (!new_value.blank?) && existing_value != new_value

        if dryrun
          puts "Conflict #{operator.id} #{operator.name} #{operator_field}: was #{existing_value} now #{new_value}"
        else
          operator.send("#{operator_field}=", new_value)
        end
      end
    end
  end

  def load_new_contact_fields(dryrun, operator, data)
    contact_fields = [:email, :contact_category, :contact_location]
    email = clean_field(data[:email])
    # some entries are not emails
    if email && ! Regexp.new("^#{MySociety::Validate.email_match_regexp}\$").match(email)
      email = nil
    end
    category = clean_field(data[:contact_category])
    if category.blank?
      category = 'Other'
    end
    if !email.blank?
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

      if id != 0
        operator = Operator.find(id)
        if operator.name != name
          puts "Name mismatch for id #{id}: #{name} vs. #{operator.name}" if dryrun
        else

          load_new_operator_fields(dryrun, operator, data)
          load_new_contact_fields(dryrun, operator, data)

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