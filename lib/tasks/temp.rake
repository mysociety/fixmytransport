namespace :temp do

  desc 'Set the data generation on existing tables'
  task :set_data_generation => :environment do

    DataGeneration.create!(:name => "Initial data load", :description => 'Data load from NPTG, NaPTAN, NOC, NPTDR on site creation')
     FixMyTransport::DataGenerations.models_existing_in_data_generations.each do |model_class|
        puts model_class
        table_name = model_class.to_s.tableize
        puts table_name
        model_class.connection.execute("UPDATE #{table_name}
                                        SET generation_low = 1, generation_high = 1")

    end
    Slug.connection.execute("UPDATE slugs SET generation_low = 1, generation_high = 1")
  end

  desc "Add replayable flag values to versions models in data generations. Indicates whether a change is
        replayable after a new generation of data is loaded"
  task :add_replayable_to_versions => :environment do
    Version.connection.execute("UPDATE versions
                                SET generation = 1;")
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
                                AND (event = 'create'
                                OR event = 'destroy')
                                AND ((date_trunc('hour', created_at) <= '2011-04-05 18:00:00')
                                OR (date_trunc('day', created_at) = '2011-04-05'
                                    AND date_trunc('hour', created_at) >= '2011-04-05 17:05:00'))")
    Version.connection.execute("UPDATE versions
                                SET replayable = 'f'
                                WHERE item_type = 'Route'
                                AND (event = 'create'
                                OR event = 'destroy')
                                AND ((date_trunc('hour', created_at) <= '2011-04-05 18:00:00')
                                OR (date_trunc('day', created_at) = '2011-04-05'
                                    AND date_trunc('hour', created_at) >= '2011-04-05 17:05:00'))")
    Version.connection.execute("UPDATE versions
                                SET replayable = 'f'
                                WHERE item_type = 'Route'
                                AND event = 'destroy'
                                AND (date_trunc('hour', created_at) = '2011-06-19 11:00:00'
                                OR date_trunc('hour', created_at) = '2011-06-19 10:00:00')")

    Version.connection.execute("UPDATE versions
                                SET replayable = 'f'
                                WHERE item_type = 'RouteOperator'
                                AND date_trunc('hour', created_at) < '2011-04-05 00:00:00'")
    Version.connection.execute("UPDATE versions
                                SET replayable = 'f'
                                WHERE item_type = 'RouteOperator'
                                AND event = 'create'
                                AND date_trunc('hour', created_at) < '2011-07-29 00:00:00'")
    Version.connection.execute("UPDATE versions
                                SET replayable = 't'
                                WHERE item_type = 'RouteOperator'
                                AND replayable is null")
  end

  desc 'Backload version records for the StopAreaLink model'
  task :backload_stop_area_link_versions => :environment do
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
      file = check_for_param('FILE')
      parser = Parsers::NaptanParser.new
      deletions = 0
      parser.parse_stop_area_links(file) do |stop_area_link|
        stop_area_link.generation_low = 1
        stop_area_link.generation_high = 1
        existing = StopAreaLink.in_generation(1).find(:first, :conditions => ['ancestor_id = ?
                                                                  AND descendant_id = ?
                                                                  AND direct = ?',
                                                                  stop_area_link.ancestor_id,
                                                                  stop_area_link.descendant_id,
                                                                  true])
        if !existing
          puts "Deleted record #{stop_area_link.ancestor.name} #{stop_area_link.ancestor_id} #{stop_area_link.descendant.name} #{stop_area_link.descendant_id}"
          PaperTrail.enabled = false
          begin
            stop_area_link.make_direct
            stop_area_link.save!
            PaperTrail.enabled = true
            stop_area_link.destroy
            deletions += 1
          rescue Exception => e
            puts e.message
            puts e.backtrace
            puts "Skipping #{stop_area_link.inspect}"
            PaperTrail.enabled = false
          end
        end
      end
      puts "Found #{deletions} deletions"
      stop_area_links = StopAreaLink.in_generation(1).find(:all, :conditions => ["date_trunc('day',created_at) > '2011-03-28 00:00:00'"])
      stop_area_links.each do |stop_area_link|
        puts "#{stop_area_link.id}"
        stop_area_link.create_initial_pt_version
      end
    end
  end

  desc 'Backload operator statuses'
  task :backload_operator_statuses => :environment do
    Operator.connection.execute("UPDATE operators
                                 SET status = 'ACT'")
  end

  desc 'Backload PTE statuses'
  task :backload_pte_statuses => :environment do
    PassengerTransportExecutive.connection.execute("UPDATE passenger_transport_executives
                                                    SET status = 'ACT'")
  end

  desc 'Backload version records for the StopAreaMembership model'
  task :backload_stop_area_membership_versions => :environment do
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
      file = check_for_param('FILE')
      parser = Parsers::NaptanParser.new
      deletions = 0
      parser.parse_stop_area_memberships(file) do |stop_area_membership|
        stop_area_membership.generation_low = 1
        stop_area_membership.generation_high = 1
        existing = StopAreaMembership.in_generation(1).find(:first, :conditions => ['stop_area_id = ?
                                                                  AND stop_id = ?',
                                                                  stop_area_membership.stop_area_id,
                                                                  stop_area_membership.stop_id])
        if !existing && ! stop_area_membership.modification == 'del'
          puts "Deleted record #{stop_area_membership.stop_area.name} #{stop_area_membership.stop_area_id} #{stop_area_membership.stop.name} #{stop_area_membership.stop_id}"
          PaperTrail.enabled = false
          stop_area_membership.save
          PaperTrail.enabled = true
          stop_area_membership.destroy
          deletions += 1
        end
      end
      puts "Found #{deletions} deletions"
      stop_area_memberships = StopAreaMembership.in_generation(1).find(:all, :conditions => ["date_trunc('day',created_at) > '2011-03-28 00:00:00'"])
      stop_area_memberships.each do |stop_area_membership|
        puts "#{stop_area_membership.id}"
        stop_area_membership.create_initial_pt_version
      end
    end

  end

  desc 'Backload version records for the StopAreaOperator model'
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
      file = check_for_param('FILE')
      parser = Parsers::OperatorsParser.new
      deletions = 0
      parser.parse_stop_area_operators(file) do |stop_area_operator|
        stop_area_operator.generation_low = 1
        stop_area_operator.generation_high = 1
        existing = StopAreaOperator.in_generation(1).find(:first, :conditions => ['stop_area_id = ?
                                                                  AND operator_id = ?',
                                                                  stop_area_operator.stop_area_id,
                                                                  stop_area_operator.operator_id])
        if !existing
          puts "Deleted record #{stop_area_operator.stop_area.name} #{stop_area_operator.operator.name}"
          PaperTrail.enabled = false
          stop_area_operator.save
          PaperTrail.enabled = true
          stop_area_operator.destroy
          deletions += 1
        end
      end
      puts "Found #{deletions} deletions"
      stop_area_operators = StopAreaOperator.in_generation(1).find(:all, :conditions => ["date_trunc('day',created_at) > '2011-03-28 00:00:00'"])
      stop_area_operators.each do |stop_area_operator|
        puts "#{stop_area_operator.id}"
        stop_area_operator.create_initial_pt_version
      end
    end
  end

  desc 'Backload merge log records'
  task :backload_merge_logs => :environment do
    Version.find_each(:conditions => ["item_type = 'Route'
                                       AND event = 'destroy'"]) do |destroyed_version|
      destroyed_route = destroyed_version.reify()
      time_limit = destroyed_version.created_at + 5.seconds
      merged_version = Version.find(:first, :conditions => ["item_type = 'Route'
                                                            AND id > ?
                                                            AND event = 'update'
                                                            AND created_at <= ?",
                                                           destroyed_version.id, time_limit],
                                            :order => 'id asc')

      if merged_version
        merged_route = merged_version.reify()
        if merged_route.number == destroyed_route.number
          MergeLog.create!(:model_name => 'Route',
                           :from_id => destroyed_route.id,
                           :to_id => merged_version.item_id,
                           :created_at => destroyed_version.created_at)
          destroyed_route_operator_versions = Version.find(:all, :conditions => ["item_type = 'RouteOperator'
                                                                   AND event = 'destroy'
                                                                   AND object like E'%%route_id: #{destroyed_route.id}\n%%'"])
          puts "Found #{destroyed_route_operator_versions.size} route operators"
          destroyed_route_operator_versions.each do |destroyed_route_operator_version|
            destroyed_route_operator = destroyed_route_operator_version.reify()
            destroyed_route_operator.route = merged_route
            if destroyed_route_operator.identity_hash_populated?
              merged_route_operator = RouteOperator.find_in_generation_by_identity_hash(destroyed_route_operator, 1)
              if merged_route_operator
                MergeLog.create!(:model_name => 'RouteOperator',
                                 :from_id => destroyed_route_operator.id,
                                 :to_id => merged_route_operator.id,
                                 :created_at => destroyed_route_operator_version.created_at)
              end
            end
          end
          puts "#{destroyed_version.id} Destruction of #{destroyed_route.id} #{destroyed_route.inspect} #{merged_version.inspect}"
        end
      end
    end
  end

  desc 'Remove duplicate location operators'
  task :remove_location_operator_duplicates => :environment do
    conditions = ['id in (SELECT a.id
                          FROM route_operators as a, route_operators as b
                          WHERE a.id > b.id
                          AND a.operator_id = b.operator_id
                          AND a.route_id = b.route_id)']
    RouteOperator.find(:all, :conditions => conditions).each do |route_operator|
      route_operator.destroy
    end
    conditions = ['id in (SELECT a.id
                          FROM stop_area_operators as a, stop_area_operators as b
                          WHERE a.id > b.id
                          AND a.operator_id = b.operator_id
                          AND a.stop_area_id = b.stop_area_id)']
    StopAreaOperator.find(:all, :conditions => conditions).each do |stop_area_operator|
      stop_area_operator.destroy
    end
  end

  desc 'Remove bad station links'
  task :remove_bad_station_links => :environment do
    codes = {'910GBCSTRTN' => '910GBCSTN',
             '910GCNTBW' => '910GCNTBE',
             '910GEDNT' => '910GEDNB',
             '910GMSTONEE' => '910GMSTONEB',
             '910GWHYTELF' => '910GUWRLNGH',
             '910GNTHCAMP' => '910GASHVALE'}

    codes.each do |ancestor_code, descendant_code|
      ancestor = StopArea.in_generation(1).find_by_code(ancestor_code)
      descendant = StopArea.in_generation(1).find_by_code(descendant_code)
      link = StopAreaLink.find_link(ancestor, descendant)
      if link
        puts "destroying #{ancestor.name} => #{descendant.name}"
        link.destroy
      end
    end
  end

  desc 'Populate the persistent_id column for models in data generations'
  task :populate_persistent_id => :environment do
    FixMyTransport::DataGenerations.models_existing_in_data_generations.each do |model_class|
      puts model_class
      table_name = model_class.to_s.tableize
      model_class.connection.execute("UPDATE #{table_name}
                                      SET persistent_id = id
                                      WHERE previous_id IS NULL
                                      AND generation_low = 1")
      model_class.connection.execute("SELECT SETVAL('#{table_name}_persistent_id_seq', (SELECT MAX(id) FROM #{table_name}) + 1);")
      model_class.connection.execute("UPDATE #{table_name}
                                      SET persistent_id = NEXTVAL('#{table_name}_persistent_id_seq')
                                      WHERE previous_id IS NULL
                                      AND generation_low != 1")
      model_class.connection.execute("UPDATE #{table_name}
                                      SET persistent_id = (SELECT persistent_id from #{table_name} as prev
                                                           WHERE prev.id = #{table_name}.previous_id)
                                      WHERE previous_id IS NOT NULL")
    end
  end

  desc 'Populate operator_contacts operator_persistent_id field'
  task :populate_operator_contacts_operator_persistent_id => :environment do
    OperatorContact.find_each(:conditions => ['operator_persistent_id is null']) do |contact|
      operator = Operator.find(:first, :conditions => ['id = ?', contact.operator_id])
      if ! operator
        puts "No operator with id #{contact.operator_id}"
        next
      end
      contact.operator_persistent_id = operator.persistent_id
      puts "Setting operator_persistent_id to #{contact.operator_persistent_id} for #{contact.id}, operator #{operator.id}"
      contact.save!
    end
  end

  desc 'Populate passenger_transport_executive_contacts passenger_transport_executive_persistent_id field'
  task :populate_passenger_transport_executive_contacts_persistent_id => :environment do
    PassengerTransportExecutiveContact.find_each(:conditions => ['passenger_transport_executive_persistent_id is null']) do |contact|
      pte = PassengerTransportExecutive.find(:first, :conditions => ['id = ?', contact.passenger_transport_executive_id])
      if ! pte
        puts "No pte with id #{contact.passenger_transport_executive_id}"
        next
      end
      contact.passenger_transport_executive_persistent_id = pte.persistent_id
      puts "Setting passenger_transport_executive_persistent_id to #{contact.passenger_transport_executive_persistent_id} for #{contact.id}, pte #{pte.id}"
      contact.save!
    end
  end

  desc 'Populate operator_contacts location_persistent_id field'
  task :populate_operator_contacts_location_persistent_id => :environment do
    OperatorContact.find_each(:conditions => ['location_persistent_id is null and location_type is not null']) do |contact|
      location_type = contact.location_type.constantize
      location = location_type.find(:first, :conditions => ['id = ?', contact.location_id])
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
      location_type = campaign.location_type.constantize
      location = location_type.find(:first, :conditions => ['id = ?', campaign.location_id])
      if ! location
        puts "No location with id #{campaign.location_id}"
        next
      end
      campaign.location_persistent_id = location.persistent_id
      puts "Setting location_persistent_id to #{campaign.location_persistent_id} for #{campaign.id}, #{location_type} #{location.id}"
      campaign.save(perform_validation=false)
    end
  end

  desc 'Populate problem location_persistent_id field'
  task :populate_problem_persistent_id => :environment do
    Problem.find_each(:conditions => ['location_persistent_id is null']) do |problem|
      location_type = problem.location_type.constantize
      location = location_type.find(:first, :conditions => ['id = ?', problem.location_id])
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
      if responsibility.organization_type == 'Operator'
        operator = Operator.find(:first, :conditions => ['id = ?', responsibility.organization_id])
        if ! operator
          puts "No operator with id #{responsibility.organization_id}"
          next
        end
        responsibility.organization_persistent_id = operator.persistent_id
        puts "Setting organization_persistent_id to #{responsibility.organization_persistent_id} for #{responsibility.id}, operator #{operator.id}"
      elsif responsibility.organization_type == 'PassengerTransportExecutive'
        pte = PassengerTransportExecutive.find(:first, :conditions => ['id = ?', responsibility.organization_id])
        if ! pte
          puts "No PTE with id #{responsibility.organization_id}"
          next
        end
        responsibility.organization_persistent_id = pte.persistent_id
        puts "Setting organization_persistent_id to #{responsibility.organization_persistent_id} for #{responsibility.id}, pte #{pte.id}"
      elsif responsibility.organization_type == 'Council'
        council = Council.find_by_id(responsibility.organization_id)
        if ! council
          puts "No council with id #{responsibility.organization_id}"
          next
        end
        responsibility.organization_persistent_id = council.id
        puts "Setting organization_persistent_id to #{responsibility.organization_persistent_id} for #{responsibility.id}, council #{council.id}"
      end
      responsibility.save!
    end
  end

  desc 'Populate transport mode for operators that were loaded from TNDS without it'
  task :backload_operator_transport_modes => :environment do
    file = check_for_param('FILE')
    verbose = check_verbose
    dryrun = check_dryrun
    tsv_data = File.read(file)
    tsv_options = { :quote_char => '"',
                    :col_sep => "\t",
                    :row_sep =>:auto,
                    :return_headers => false,
                    :headers => :first_row,
                    :encoding => 'N' }
    new_data = {}
    manual_matches = { 'First in Greater Manchester' => 'First Manchester',
                       'Grovesnor Coaches' => 'Grosvenor Coaches',
                       'TC Minicoaches' => 'T C Minicoaches',
                       'Fletchers Coaches' => "Fletcher's Coaches",
                       'Select Bus & Coach Servi' => 'Select Bus & Coach',
                       'Landmark Coaches' => 'Landmark  Coaches',
                       'Romney Hythe and Dymchu' => 'Romney Hythe & Dymchurch Light Railway',
                       'Sovereign Coaches' => 'Sovereign',
                       'TM Travel' => 'T M Travel Ltd',
                       'First in London' => 'First (in the London area)',
                       'First in Berkshire & Th' => 'First (in the Thames Valley)',
                       'First in Calderdale & H' => 'First Huddersfield',
                       'First in Essex' => 'First (in the Essex area)',
                       'First in Greater Manche' => 'First Manchester',
                       'First in Suffolk & Norf' => 'First Eastern Counties (First Suffolk & Norfolk)',
                       'Yourbus' => 'Your Bus',
                       'Andybus &amp; Coach' => 'Andybus & Coach Ltd',
                       'AJ & NM Carr' => 'A J & N M Carr',
                       'AP Travel' => 'AP Travel Ltd',
                       'Ad&apos;Rains Psv' => "AD'RAINS PSV",
                       'Anitas Coaches' => "Anita's Coaches",
                       'B&NES' => 'Bath & North East Somerset Council',
                       'Bath Bus Company' => 'Bath Bus Co Ltd',
                       'Briggs Coach Hire' => 'Briggs Coaches',
                       'Centrebus (Beds Herts &' => 'Centrebus (Beds & Herts area)',
                       'Eagles Coaches' => 'Eagle Coaches',
                       'First in Bristol, Bath & the West' => 'First Bristol',
                       'Green Line (operated by Arriva the Shires)' => 'Green Line (operated by Arriva the Shires & Essex)',
                       'Green Line (operated by First in Berkshire)' => 'Green Line (operated by First - Thames Valley)',
                       'H.C.Chambers & Son' => 'H C Chambers & Son',
                       'Holloways Coaches' => 'Holloway Coaches',
                       'Kimes Coaches' => 'Kimes',
                       'P&O Ferries' => 'P & O Ferries',
                       'RH Transport' => 'R H Transport',
                       "Safford's Coaches" => 'Safford Coaches',
                       'Travel West Midlands' => 'National Express West  Midlands (NXWM)'
                       }
    FasterCSV.parse(tsv_data, tsv_options) do |row|
      region = row['Region']
      operator_code = row['Code']
      short_name = row['Short name']
      trading_name = row['Trading name']
      license_name = row['Name on license']
      problem = row['Problem']
      file = row['File']
      transport_mode_name = row['Transport mode']

      if short_name.blank?
        puts "No short name in line #{row.inspect}" if short_name.blank?
        next
      end

      operator_info = { :short_name => short_name,
                        :trading_name => trading_name,
                        :license_name => license_name,
                        :transport_mode => transport_mode_name }

      if !new_data[operator_info]
        new_data[operator_info] = 1
        puts "Looking for #{short_name} #{trading_name} #{license_name}" if verbose
        if manual_name = (manual_matches[short_name] || manual_matches[trading_name])
          operators = Operator.current.find(:all, :conditions => ['lower(name) = ?', manual_name.downcase])
        else
          operators = operators_from_info(short_name, license_name, trading_name, verbose)
          if operators.empty?
            short_name_canonical = short_name.gsub('First in', 'First')
            short_name_canonical = short_name_canonical.gsub('.', '')
            short_name_canonical = short_name_canonical.gsub('Stagecoach', 'Stagecoach in')
            short_name_canonical = short_name_canonical.gsub('&amp;', '&')
            if short_name_canonical != short_name
              operators = Operator.current.find(:all, :conditions => ['lower(name) = ?',
                                                                       short_name_canonical.downcase])
            end
           end
        end
        if operators.size == 1
          operator = operators.first
          if operator.transport_mode_id.nil?
            operator.transport_mode = TransportMode.find_by_name(transport_mode_name)
            puts "Setting transport mode for #{operator.name} to #{transport_mode_name}"
            if ! dryrun
              operator.save!
            end
          end
        end
      end
    end
  end


  desc 'Retry operator finding for routes without operators (to be run once transport mode ids are backloaded)'
  task :retry_route_operator_matching => :environment do

    Route.find_current_without_operators().each do |route|

      source_codes = route.route_sources.map{ |route_source| [route_source.operator_code, route_source.region] }.uniq
      if source_codes.size == 1
        operator_code, region = source_codes.first
        operators = Operator.find_all_current_by_nptdr_code(route.transport_mode, operator_code, region, route)
        if operators.size == 1
          puts "Assigning route #{route.number} #{operator_code} to operator #{operators.first.name}"
        end
      end
    end
  end

end
