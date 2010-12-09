namespace :temp do

  desc 'Populate the transport_mode_id column in existing operator records'
  task :populate_operator_transport_mode_id => :environment do 
    Operator.find_each do |operator|
      if !operator.vehicle_mode.blank?
        operator.transport_mode = Operator.vehicle_mode_to_transport_mode(operator.vehicle_mode)
        puts "Setting transport mode to #{operator.transport_mode.name} for #{operator.vehicle_mode}"
        operator.save!
      end
    end
  end
  
end