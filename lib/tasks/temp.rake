require File.dirname(__FILE__) +  '/data_loader'
namespace :temp do

  desc 'Set the data generation on existing tables'
  task :set_data_generation => :environment do

    DataGeneration.create!(:name => "Initial data load", :description => 'Data load from NPTG, NaPTAN, NOC, NPTDR on site creation')
     FixMyTransport::DataGenerations.models_existing_in_data_generations.each do |model_class|
        puts model_class
        table_name = model_class.to_s.tableize
        puts table_name
        next if [JourneyPattern, RouteSegment].include?(model_class)
        model_class.connection.execute("UPDATE #{table_name}
                                        SET generation_low = 1, generation_high = 1")
    end

  end

  desc "Add replayable flag values to versions models in data generations. Indicates whether a change is
        replayable after a new generation of data is loaded"
  task :add_replayable_to_versions => :environment do
    Version.connection.execute("UPDATE versions
                                SET replayable = 'f'
                                WHERE item_type = 'Stop'
                                AND (date_trunc('day', created_at) = '2011-03-02'
                                OR date_trunc('day', created_at) = '2011-03-03'
                                OR date_trunc('hour', created_at) = '2011-03-23 19:00:00'
                                OR (date_trunc('day', created_at) = '2011-03-03'
                                AND event = 'update')
                                OR date_trunc('day', created_at) = '2011-06-08'
                                OR (date_trunc('day', created_at) = '2011-04-07'
                                    AND date_trunc('hour', created_at) >= '2011-04-07 17:00:00'
                                    AND event = 'update')
                                OR date_trunc('day', created_at) = '2011-06-21'
                                OR date_trunc('day', created_at) = '2011-06-22')")
    Version.connection.execute("UPDATE versions
                                SET replayable = 't'
                                WHERE item_type = 'Stop'
                                AND replayable is null;")

    Version.connection.execute("UPDATE versions
                                SET replayable = 'f'
                                WHERE item_type = 'StopArea'
                                AND (date_trunc('day', created_at) = '2011-03-28'
                                OR date_trunc('day', created_at) = '2011-06-21')")
    Version.connection.execute("UPDATE versions
                                SET replayable = 't'
                                WHERE item_type = 'StopArea'
                                AND replayable is null;")

    Version.connection.execute("UPDATE versions
                                SET replayable = 'f'
                                WHERE item_type = 'Operator'
                                AND (date_trunc('day', created_at) = '2011-03-03')")
    Version.connection.execute("UPDATE versions
                                SET replayable = 't'
                                WHERE item_type = 'Operator'
                                AND replayable is null;")

    Version.connection.execute("UPDATE versions
                                SET replayable = 'f'
                                WHERE item_type = 'Route'
                                AND ((date_trunc('hour', created_at) <= '2011-04-05 18:00:00')
                                OR (date_trunc('day', created_at) = '2011-04-05'
                                    AND date_trunc('hour', created_at) >= '2011-04-05 17:05:00'))")
    Version.connection.execute("UPDATE versions
                                SET replayable = 't'
                                WHERE item_type = 'Route'
                                AND replayable is null")
  end

  desc 'Backload Version records for the StopAreaOperator model'
  task :backload_stop_area_operator_versions => :environment do
    #MONKEY PATCH
    module PaperTrail
      module Model
        module InstanceMethods
          def create_initial_pt_version
            record_create if versions.blank?
            puts "created #{self.class} #{self.id}"
          end

        end
      end
    end

    FixMyTransport::DataGenerations.in_generation(1) do
      file = check_for_file
      parser = Parsers::OperatorsParser.new
      deletions = 0
      parser.parse_stop_area_operators(file) do |stop_area_operator|
        stop_area_operator.generation_low = 1
        stop_area_operator.generation_high = 1
        existing = StopAreaOperator.find(:first, :conditions => ['stop_area_id = ?
                                                                  AND operator_id = ?',
                                                                  stop_area_operator.stop_area_id,
                                                                  stop_area_operator.operator_id])
        if !existing
          puts "Deleted record #{stop_area_operator.stop_area.name} #{stop_area_operator.operator.name}"
          StopAreaOperator.paper_trail_off
          stop_area_operator.save
          StopAreaOperator.paper_trail_on
          stop_area_operator.destroy
          deletions += 1
        end
      end
      puts "Found #{deletions} deletions"
      stop_area_operators = StopAreaOperator.find(:all, :conditions => ["date_trunc('day',created_at) > '2011-03-28 00:00:00'"])
      stop_area_operators.each do |stop_area_operator|
        puts "#{stop_area_operator.id}"
        stop_area_operator.create_initial_pt_version
      end
    end
  end


  desc 'Populate the persistent_id column for models in data generations'
  task :populate_persistent_id => :environment do
    FixMyTransport::DataGenerations.models_existing_in_data_generations.each do |model_class|
      puts model_class
      table_name = model_class.to_s.tableize
      next if [JourneyPattern, RouteSegment].include?(model_class)
      model_class.connection.execute("UPDATE #{table_name}
                                      SET persistent_id = id
                                      WHERE previous_id IS NULL
                                      AND generation_low = 1")
      model_class.connection.execute("SELECT SETVAL('#{table_name}_persistent_id_seq', (SELECT MAX(id) FROM #{table_name}) + 1);")
      model_class.connection.execute("UPDATE #{table_name}
                                      SET persistent_id = NEXTVAL('#{table_name}_persistent_id_seq')
                                      WHERE previous_id IS NULL")
      model_class.connection.execute("UPDATE #{table_name}
                                      SET persistent_id = (SELECT persistent_id from #{table_name} as prev
                                                           WHERE prev.id = #{table_name}.previous_id)
                                      WHERE previous_id IS NOT NULL")
    end
  end

  desc 'Populate the persistent_id column for sub_routes'
  task :populate_sub_routes_persistent_ids => :environment do
    SubRoute.find_each do |sub_route|
      # puts sub_route.inspect
      from_station = nil
      to_station = nil
      StopArea.in_any_generation do
        from_station = StopArea.find(:first, :conditions => ['id = ?', sub_route.from_station_id])
        to_station = StopArea.find(:first, :conditions => ['id = ?', sub_route.to_station_id])
      end
      if ! from_station
        puts "No stop area with id #{sub_route.from_station_id}"
        next
      end
      if ! to_station
        puts "No stop area with id #{sub_route.to_station_id}"
        next
      end
      SubRoute.connection.execute("UPDATE sub_routes
                                   SET from_station_persistent_id = #{from_station.persistent_id},
                                       to_station_persistent_id = #{to_station.persistent_id},
                                       persistent_id = #{sub_route.id}
                                   WHERE id = #{sub_route.id}")
      sub_route = SubRoute.find(sub_route.id)
      if ! sub_route.from_station
        puts "From station (id #{from_station.id}) does not exist in current generation"
      end
      if ! sub_route.to_station
        puts "To station (id #{to_station.id}) does not exist in current generation"
      end
    end
  end

  desc 'Populate operator_contacts operator_persistent_id field'
  task :populate_operator_contacts_operator_persistent_id => :environment do
    OperatorContact.find_each(:conditions => ['operator_persistent_id is null']) do |contact|
      operator = nil
      Operator.in_any_generation do
        operator = Operator.find(:first, :conditions => ['id = ?', contact.operator_id])
      end
      if ! operator
        puts "No operator with id #{contact.operator_id}"
        next
      end
      contact.operator_persistent_id = operator.persistent_id
      puts "Setting operator_persistent_id to #{contact.operator_persistent_id} for #{contact.id}, operator #{operator.id}"
      contact.save!
    end
  end

  desc 'Populate operator_contacts location_persistent_id field'
  task :populate_operator_contacts_location_persistent_id => :environment do
    OperatorContact.find_each(:conditions => ['location_persistent_id is null and location_type is not null']) do |contact|
      location = nil
      location_type = contact.location_type.constantize
      location_type.in_any_generation do
        location = location_type.find(:first, :conditions => ['id = ?', contact.location_id])
      end
      if ! location
        puts "No #{location_type} with id #{contact.location_id}"
        next
      end
      contact.location_persistent_id = location.persistent_id
      puts "Setting location_persistent_id to #{contact.location_persistent_id} for #{contact.id}, location #{location.id}"
      contact.save!
    end
  end

  desc 'Populate campaign location_persistent_id field'
  task :populate_campaign_persistent_id => :environment do
    Campaign.find_each(:conditions => ['location_persistent_id is null']) do |campaign|
      location = nil
      location_type = campaign.location_type.constantize
      location_type.in_any_generation do
        location = location_type.find(:first, :conditions => ['id = ?', campaign.location_id])
      end
      if ! location
        puts "No location with id #{campaign.location_id}"
        next
      end
      campaign.location_persistent_id = location.persistent_id
      puts "Setting location_persistent_id to #{campaign.location_persistent_id} for #{campaign.id}, #{location_type} #{location.id}"
      campaign.save!
    end
  end

  desc 'Populate problem location_persistent_id field'
  task :populate_problem_persistent_id => :environment do
    Problem.find_each(:conditions => ['location_persistent_id is null']) do |problem|
      location = nil
      location_type = problem.location_type.constantize
      location_type.in_any_generation do
        location = location_type.find(:first, :conditions => ['id = ?', problem.location_id])
      end
      if ! location
        puts "No location with id #{problem.location_id}"
        next
      end
      problem.location_persistent_id = location.persistent_id
      puts "Setting location_persistent_id to #{problem.location_persistent_id} for #{problem.id}, #{location_type} #{location.id}"
      problem.save!
    end
  end

  desc 'Populate responsibilities organization_persistent_id field'
  task :populate_responsibility_organization_persistent_id => :environment do
    Responsibility.find_each(:conditions => ['organization_persistent_id is null']) do |responsibility|
      operator = nil
      if responsibility.organization_type == 'Operator'
        Operator.in_any_generation do
          operator = Operator.find(:first, :conditions => ['id = ?', responsibility.organization_id])
        end
        if ! operator
          puts "No operator with id #{responsibility.organization_id}"
          next
        end
        responsibility.organization_persistent_id = operator.persistent_id
        puts "Setting organization_persistent_id to #{responsibility.organization_persistent_id} for #{responsibility.id}, operator #{operator.id}"
      end

    end
  end

end
