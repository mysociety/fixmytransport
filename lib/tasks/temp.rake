namespace :temp do
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
    SubRoute.find(:all).each do |sub_route|
      write_mapping_line(sub_route.from_station)
      write_mapping_line(sub_route.to_station)
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
              identifying_data[:route_description],
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
end
