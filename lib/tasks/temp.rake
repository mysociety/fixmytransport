require 'fastercsv'
namespace :temp do
  
  def remap_problem_line(line, remaps)
    line = remap_line(line, location_id_position=3, location_type_position=4, remaps)
  end
  
  def remap_campaign_line(line, remaps)
    line = remap_line(line, location_id_position=1, location_type_position=2, remaps)
  end
  
  def remap_line(line, location_id_position, location_type_position, remaps)
    fields = line.split("\t")
    location_id = fields[location_id_position]
    location_type = fields[location_type_position].constantize
    puts "#{location_id} #{location_type}"
    fields[location_id_position] = get_remap(location_type, location_id, remaps, fields[location_id_position])
    return fields.join("\t")
  end
  
  def get_remap(location_type, location_id, remaps, default)
    case location_type
    when Stop
      remaps[:stops][location_id]
    when StopArea
      remaps[:stop_areas][location_id]
    when Route
      remaps[:routes][location_id]
    else 
      default
    end
  end
  
  def csv_options
    { :quote_char => '"',
      :col_sep =>"\t",
      :row_sep =>:auto,
      :return_headers => false,
      :headers => :first_row,
      :encoding => 'N' }
  end
  
  def map_locations(dir)
    remaps = {:stops => {}, 
              :stop_areas => {}, 
              :routes => {}, 
              :operators => {},
              :council_contacts => {}, 
              :operator_contacts => {}}
    mapping_data = File.read(File.join(dir, 'mappings.tsv'))
    headers = ['Instance Type',
               'Instance ID', 
               'Stop ATCO code',
               'Stop area code', 
               'Route transport mode id',
               'Route number', 
               'Route operator code', 
               'Route description',
               'Operator name',
               'Operator code',
               'Council contact area id', 
               'Council contact category',
               'Council contact email',
               'Operator contact operator id',
               'Operator contact location id', 
               'Operator contact location type',
               'Operator contact email',
               'Operator contact category']
    FasterCSV.parse(mapping_data, csv_options) do |line|
      location_type = line['Instance Type']
      location_id = line['Instance ID'].to_i
      puts "#{location_type} #{location_id}"
      case location_type
      when 'Stop'
        atco_code = line['Stop ATCO code']
        mapped_stop = Stop.find_by_atco_code(atco_code)
        raise "Couldn't map stop #{atco_code}" unless mapped_stop
        remaps[:stops][location_id] = mapped_stop.id
      when 'StopArea'
        code = line['Stop area code']
        mapped_stop_area = StopArea.find_by_code(code)
        raise "Couldn't map stop area #{code}" unless mapped_stop_area
        remaps[:stop_areas][location_id] = mapped_stop_area.id
      when 'Route', 'TrainRoute', 'BusRoute', 'TramMetroRoute'
        transport_mode_id = line['Route transport mode id']
        number = line['Route number']
        operator_code = line['Route operator code']
        description = line['Route description']
        mapped_locations = Route.find(:all, :conditions => ['transport_mode_id = ? 
                                                             AND (number = ? or cached_description = ?)
                                                             AND operator_code = ?',
                                                             transport_mode_id, number, description, operator_code])
        if mapped_locations.size == 1
          mapped_route = mapped_locations.first
          remaps[:routes][location_id] = mapped_route.id
        else
          puts "Couldn't map route #{transport_mode_id} #{number} #{operator_code}"
        end
      when 'Operator'
        operator_name = line['Operator name']
        operator_code = line['Operator code']
        if operator_name == 'Test Operator'
          mapped_operators = Operator.find(:all, :conditions => ['lower(name) = ?', operator_name.downcase])
        else
          mapped_operators = Operator.find(:all, 
                                           :conditions => ["lower(name) = ? 
                                                            and operator_codes.code = ?", 
                                                            operator_name.downcase, operator_code], 
                                           :include => :operator_codes)
        end
        manual_operator_mappings = { 'National Express West Midlands' => 'West Midlands Travel',
                                     'First Scotrail' => 'ScotRail', 
                                     'London Underground' => 'London Underground (TfL)', 
                                     'First Great Western' => 'First Great Western Railway', 
                                     'Network Rail' => 'Network Rail', 
                                     'Stagecoach East Midlands' => 'Stagecoach in Bassetlaw', 
                                     'Countryliner Coach Hire' => 'Countryliner Coach Hire', 
                                     'Abellio' => 'Abellio London', 
                                     'First' => 'Surrey Connect', 
                                     'First South Yorkshire Ltd' => 'First South Yorkshire',
                                     'London United' => 'Transdev London United'}
        if mapped_operators.empty? and manual_operator_mappings.keys.include?(operator_name)
          mapped_operators = Operator.find(:all, 
                                           :conditions => ["lower(name) = ? ", 
                                                            manual_operator_mappings[operator_name].downcase], 
                                           :include => :operator_codes)
        end
        if mapped_operators.size == 1
          remaps[:operators][location_id] = mapped_operators.first.id
        else
          raise "Couldn't map operator #{operator_name} #{mapped_operators.inspect}"
        end
      when 'CouncilContact'
        area_id = line['Council contact area id']
        category = line['Council contact category']
        email = line['Council contact email']
        mapped_contacts = CouncilContact.find(:all, :conditions => ['area_id = ? 
                                                                    AND category = ?
                                                                    AND email = ?',
                                                                    area_id, category, email])
        if mapped_contacts.size == 1
          remaps[:council_contacts][location_id] = mapped_contacts.first
        else
          raise "Couldn't map council contact area #{area_id} #{category} #{email}"
        end
      when 'OperatorContact'
        operator_id = line['Operator contact operator id']
        operator_location_id = line['Operator contact location id'] 
        operator_email = line['Operator contact email']
        category = line['Operator contact category']
        puts operator_email
        puts category
        new_operator_id = remaps[:operators][operator_id.to_i]
        if operator_location_id 
          mapped_contacts = OperatorContact.find(:all, :conditions => ['operator_id = ?
                                                                        AND location_id = ?
                                                                        AND email = ?
                                                                        AND category = ?',
                                                                        new_operator_id, operator_location_id, operator_email, category])
        else
          mapped_contacts = OperatorContact.find(:all, :conditions => ['operator_id = ?
                                                                        AND location_id is null
                                                                        AND email = ?
                                                                        AND category = ?',
                                                                        new_operator_id, operator_email, category])

        end
        if mapped_contacts.size == 1
          remaps[:operator_contacts][location_id] = mapped_contacts.first
        else
          raise "Couldn't map operator contact #{new_operator_id} #{operator_location_id} #{operator_email} #{category}"
        end
      else 
        raise "Unrecognized location type #{location_type} when mapping locations"
      end
    end
    return remaps
  end
  
  task :create_test_data => :environment do 
    ActiveRecord::Base.transaction do 
    test_operator = Operator.create!(:name => 'Test Operator', 
                                    :notes => 'A fake operator for testing')
    operator_contact = OperatorContact.create!(:operator => test_operator, 
                                              :category => 'Other',
                                              :email => 'louise@mysociety.org')
    route_segment = RouteSegment.new(:from_stop_id => 311409, 
                                     :to_stop_id => 311410,
                                     :from_terminus => true, 
                                     :to_terminus => true)
    test_route = BusRoute.create!(:number => 'ZZ9', 
                                  :region_id => 4,
                                 :journey_patterns => [JourneyPattern.new(:route_segments => [route_segment])], 
                                 :transport_mode_id => 1)
    route_operator = RouteOperator.create!(:route => test_route, 
                                          :operator => test_operator)
    end
  end
  
  task :create_mappings => :environment do 
    check_for_dir
    dir = ENV['DIR']
    mapping_file = File.open(File.join(dir, 'mappings.tsv'), 'w')
    headers = ['Instance Type',
               'Instance ID', 
               'Stop ATCO code',
               'Stop area code', 
               'Route transport mode id',
               'Route number', 
               'Route operator code', 
               'Operator name',
               'Operator code',
               'Council contact area id', 
               'Council contact category',
               'Council contact email',
               'Operator contact operator id',
               'Operator contact location id', 
               'Operator contact email',
               'Operator contact category']
    mapping_file.write(headers.join("\t") + "\n")
    Problem.find(:all).each do |problem|
      case problem.location
      when Stop
        write_mapping_line(problem.location, mapping_file)
      when StopArea
        write_mapping_line(problem.location, mapping_file)
      when Route 
        write_mapping_line(problem.location, mapping_file)
      when SubRoute
        write_mapping_line(problem.location.from_station, mapping_file)
        write_mapping_line(problem.location.to_station, mapping_file)
        problem.location.routes.each do |route|
          write_mapping_line(route, mapping_file)
        end
      else 
        raise "Unexpected type of problem location #{problem.location.type}"
      end
      if problem.operator
        write_mapping_line(problem.operator, mapping_file)
      end
    end
    OutgoingMessage.find(:all).each do |outgoing_message|
      case outgoing_message.recipient
      when CouncilContact
        write_mapping_line(outgoing_message.recipient, mapping_file)
      when OperatorContact
        write_mapping_line(outgoing_message.recipient, mapping_file)
      when NilClass
      when PassengerTransportExecutive
      else
        raise "Unexpected type of outgoing message recipient #{outgoing_message.recipient.type}"
      end
    end
    SentEmail.find(:all).each do |sent_email|
      case sent_email.recipient
      when CouncilContact
        write_mapping_line(sent_email.recipient, mapping_file)
      when OperatorContact
        write_mapping_line(sent_email.recipient, mapping_file)
      when NilClass
      when User
      when PassengerTransportExecutive
      else raise "Unexpected type of sent email recipient #{sent_email.recipient.type}"
      end
    end
    
    mapping_file.close()
  end
  
  def write_mapping_line(instance, mapping_file)
    case instance
    when Stop
      identifying_data = {:stop_atco_code => instance.atco_code}
    when StopArea
      identifying_data = {:stop_area_code => instance.code}
    when Route 
      identifying_data = {:route_transport_mode_id => instance.transport_mode_id, 
                          :route_number => instance.number, 
                          :route_operator_code => instance.operator_code, 
                          :route_description => instance.description }
    when Operator
      identifying_data = {:operator_name => instance.name, 
                          :operator_code => instance.code}
    when CouncilContact
      identifying_data = {:council_contact_area_id => instance.area_id,
                          :council_contact_category => instance.category, 
                          :council_contact_email => instance.email}
    when OperatorContact
      identifying_data = {:operator_contact_operator_id => instance.operator_id,
        :operator_contact_location_id => instance.location_id, 
        :operator_contact_location_type => instance.location_type, 
        :operator_contact_email => instance.email,
        :operator_contact_category => instance.category}
    else 
      raise "Unexpected type of instance to map #{instance.type}"
    end
    fields = [instance.type, 
              instance.id, 
              identifying_data[:stop_atco_code], 
              identifying_data[:stop_area_code], 
              identifying_data[:route_transport_mode_id], 
              identifying_data[:route_number],
              identifying_data[:route_operator_code],
              identifying_data[:operator_name],
              identifying_data[:operator_code], 
              identifying_data[:council_contact_area_id],
              identifying_data[:council_contact_category],
              identifying_data[:council_contact_email],
              identifying_data[:operator_contact_operator_id],
              identifying_data[:operator_contact_location_id],
              identifying_data[:operator_contact_location_type],
              identifying_data[:operator_contact_email],
              identifying_data[:operator_contact_category]]
    mapping_file.write(fields.join("\t")+"\n")
    puts "writing"
  end

  
  desc 'Dump sql files for tables that contain user data into a directory identfied by DIR'
  task :dump_user_tables => :environment do 
    check_for_dir
    port = ENV['PORT']
    database = ENV['DATABASE']
    user = ENV['USER']
    dir = ENV['DIR']
    user_tables = [:assignments, 
                   :campaign_events, 
                   :campaign_supporters, 
                   :campaign_updates, 
                   :campaigns, 
                   :comments, 
                   :incoming_messages,
                   :location_searches,
                   :outgoing_messages, 
                   :problems, 
                   :raw_emails,
                   :route_sub_routes,
                   :sent_emails,
                   :sessions,
                   :sub_routes,
                   :updates, 
                   :users]
    user_tables.each do |user_table|
      output_file = File.join(dir, "#{user_table}.sql")
      system("pg_dump --port=#{port} --data-only -t #{user_table} -U #{user} #{database} > #{output_file}")
    end
    
    # campaigns - location_id, location_type
    campaigns_data = File.read(File.join(dir,"campaigns.sql"))
    campaigns_output = File.open(File.join(dir,"campaigns_remapped.sql"), 'w')
    data_section = false
    remaps = map_locations(dir)
    campaigns_data.each do |line|
    
      if /^\\.$/.match(line)
        data_section = false
      end
      if data_section
        campaigns_output.write(remap_campaign_line(line, remaps))
      else 
        campaigns_output.write(line)
      end
      if /^COPY campaigns.*FROM stdin;/.match(line)
        data_section = true
      end
    end
    # # problems - location_id, location_type, operator_id
    # problems_data = File.read(File.join(dir, "problems.sql"))
    # problems_output = File.open(File.join(dir, "problems_remapped.sql"), 'w')
    # data_section = false
    # problems_data.each do |line|
    #   if /^\\.$/.match(line)
    #     data_section = false
    #   end
    #   if data_section
    #     problems_output.write(remap_problem_line(line, remaps))
    #   else 
    #     problems_output.write(line)
    #   end
    #   if /^COPY problems.*FROM stdin;/.match(line)
    #     data_section = true
    #   end
    # end
    # outgoing messages receipient id, recipient type
    # sub_routes - from_station_id, to_station_id
    # routes_sub_routes - route_id
    #sent messages - recipient id, recipient_type
    # assignments - data[:operators]
  end
  
end
