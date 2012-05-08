namespace :temp do

  desc 'Set the data generation on existing tables'
  task :set_data_generation => :environment do
    DataGeneration.create!(:name => "Initial data load", :description => 'Data load from NPTG, NaPTAN, NOC, NPTDR on site creation')
    Region.connection.execute("update regions set generation_low = 1, generation_high = 1")
    AdminArea.connection.execute("update admin_areas set generation_low = 1, generation_high = 1")
    District.connection.execute("update districts set generation_low = 1, generation_high = 1")
    Locality.connection.execute("update localities set generation_low = 1, generation_high = 1")
    Slug.connection.execute("update slugs set generation_low = 1, generation_high = 1")
    Stop.connection.execute("update stops set generation_low = 1, generation_high = 1")
    StopArea.connection.execute("update stop_areas set generation_low = 1, generation_high = 1")
    StopAreaMembership.connection.execute("update stop_area_memberships set generation_low = 1, generation_high = 1")
    Operator.connection.execute("update operators set generation_low = 1, generation_high = 1")
    OperatorCode.connection.execute("update operator_codes set generation_low = 1, generation_high = 1")
    VosaLicense.connection.execute("update vosa_licenses set generation_low = 1, generation_high = 1")
    Route.connection.execute("update routes set generation_low = 1, generation_high = 1")
    RouteOperator.connection.execute("update route_operators set generation_low = 1, generation_high = 1")
    JourneyPattern.connection.execute("update journey_patterns set generation_low = 1, generation_high = 1")
    RouteSegment.connection.execute("update route_segments set generation_low = 1, generation_high = 1")

  end

  desc 'Update campaign slugs that end in a trailing hyphen'
  task :update_trailing_hyphen_slugs => :environment do

    Campaign.visible.each do |campaign|
      if campaign.to_param.last == '-'
        campaign.save
      end
    end

  end


  desc 'Transfer NXEA routes to Greater Anglia'
  task :transfer_nxea_routes_to_greater_anglia => :environment do
    operator = Operator.find_by_name('National Express East Anglia')
    new_operator = Operator.find_by_name('Greater Anglia')
    raise "Couldn't find NXEA" unless operator
    operator.route_operators.each do |route_operator|
      route = route_operator.route
      StopAreaOperator.create!(:operator => new_operator, :route => route)
      puts route_operator.id
      route_operator.destroy
    end
    operator.stop_area_operators.each do |stop_area_operator|
      stop_area = stop_area_operator.stop_area
      StopAreaOperator.create!(:operator => new_operator, :stop_area => stop_area)
      puts stop_area_operator.id
      stop_area_operator.destroy
    end
  end

  desc 'Transfer issues from station part stop areas'
  task :transfer_issues_from_station_part_stop_areas => :environment do
    StopArea.find_each(:conditions => ['area_type in (?)', StopAreaType.primary_types]) do |stop_area|
      stop_area.ancestors.each do |ancestor|
        if stop_area.area_type == ancestor.area_type && ancestor.ancestors == []
          issues = Problem.find_recent_issues(nil, { :location => stop_area })
          issues.each do |issue|
            puts "#{issue.class.to_s} #{issue.id} #{stop_area.name} #{ancestor.name}"
            issue.update_attribute('location_id', ancestor.id)
            if issue.is_a?(Campaign)
              issue.problem.update_attribute('location_id', ancestor.id)
            end
          end
        end
      end
    end
  end

  desc "Set user seen boolean flag on existing issues"
  task :set_user_seen => :environment do
    Campaign.connection.execute("UPDATE campaigns
                                 SET initiator_seen = 't'
                                 WHERE status_code in (#{Campaign.visible_status_codes.join(",")})")
    Problem.connection.execute("UPDATE problems
                                SET reporter_seen = 't'
                                WHERE problems.status_code in (#{Problem.visible_status_codes.join(",")})
                                AND campaign_id is null")
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

  desc 'Populate the persistent_id column for models in data generations'
  task :populate_persistent_id => :environment do
    FixMyTransport::DataGenerations.models_existing_in_data_generations.each do |model_class|
      puts model_class
      table_name = model_class.to_s.tableize
      next if [JourneyPattern, RouteSegment].include?(model_class)
      model_class.connection.execute("UPDATE #{table_name}
                                      SET persistent_id = NEXTVAL('#{table_name}_persistent_id_seq')
                                      WHERE persistent_id IS NULL
                                      AND previous_id IS NULL")
      model_class.connection.execute("UPDATE #{table_name}
                                      SET persistent_id = (SELECT persistent_id from #{table_name} as prev
                                                           WHERE prev.id = #{table_name}.previous_id)
                                      WHERE persistent_id IS NULL
                                      AND previous_id IS NOT NULL")
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

  desc 'Add example problems to each guide'
  task :add_guide_examples => :environment do
    { "accessibility" =>
      ["make-all-buses-wheelchair-accessible",
       "make-wheelchair-users-lives-easier",
       "make-this-bus-stop-more-accessible-f",
       "make-preston-park-train-station-acce",
       "improve-disabled-access-to-mile-end"],

      "bus_stop_fixed" =>
      ["fix-the-rubbish-bus-shelter-on-skirsa-st-cadder-gl",
       "add-a-bus-stop-on-woodhouse-lane-in",
       "help-me-get-the-bus-stop-replaced-on-manchester-ro",
       "replace-my-bus-shelter-that-was-destroyed-by-a-car",
       "erect-a-bus-shelter-at-the-bottom-en",
       "put-up-a-bus-shelter-at-harold-wood",
       "fix-hillside-road-bus-stop-opposite",
       "make-this-bus-stop-more-accessible-f"],

      "rude_staff" =>
      ["please-help-me-persuade-tfl-to-preve",
       "stop-rude-and-dangerous-drivers",
       "have-friendlier-and-fewer-ticket-che",
       "fix-this-rude-bus-driver--6",
       "improve-their-customer-service"],

      "discontinued_bus" =>
      ["give-people-living-in-claverham-and",
       "improve-termination-stop-locations-f",
       "reinstate-the-twice-an-hour-number-3",
       "restore-369-links",
       "reinstate-the-full-73-bus-route-to-s",
       "reinstate-rheola-and-pentreclwydau-t",
       "bring-back-the-17a-bus-to-derby-road"],

      "delayed_bus" =>
      ["persuade-national-express-to-add-mor",
       "give-people-living-in-claverham-and",
       "provide-adequate-seating-for-the-bus-stop-on-welli",
       "make-the-bus-come-on-time",
       "fix-this-636-bus-lateearlyfull--2",
       "fix-this-late--6",
       "first-morning-350-scunthorpe-to-hull"],

      "overcrowding" =>
      ["add-extra-carriages-onto-the-last-tr",
       "fix-the-overcrowding-on-the-severn-b",
       "make-commuter-trains-three-carriages",
       "put-more-carriages-on-the-barnstaple"]

    }.each do |partial_name, slugs|
      g = Guide.find_by_partial_name partial_name
      slugs.each do |slug|
        campaign = Campaign.find_by_cached_slug(slug)
        if campaign
          if g.campaigns.include? campaign
            puts "The campaign #{slug} was already there - not adding..."
          else
            puts "It wasn't there already - adding #{slug}..."
            g.campaigns << campaign
            g.save
          end
        else
          puts "Ignoring missing campaign: #{slug}"
        end
      end
    end
  end

end
