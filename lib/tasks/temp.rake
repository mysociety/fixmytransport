namespace :temp do

  desc 'Update campaign slugs that end in a trailing hyphen'
  task :update_trailing_hyphen_slugs => :environment do

    Campaign.visible.each do |campaign|
      if campaign.to_param.last == '-'
        campaign.save
      end
    end

  end

  desc 'Transfer Bowers routes to High Peak Centrebus'
  task :transfer_bowers_routes_to_high_peak => :environment do
    bowers = Operator.find_by_name('Bowers Coaches')
    high_peak = Operator.find_by_name('High Peak Centrebus')
    raise "Couldn't find Bowers" unless bowers
    raise "Couldn't find High Peak" unless high_peak
    bowers.route_operators.each do |route_operator|
      route = route_operator.route
      RouteOperator.create!(:operator => high_peak, :route => route)
      puts route_operator.id
      route_operator.destroy
    end
  end

  desc 'Transfer NXEA routes to Greater Anglia'
  task :transfer_nxea_routes_to_greater_anglia => :environment do
    operator = Operator.find_by_name('National Express East Anglia')
    new_operator = Operator.find_by_name('Greater Anglia')
    raise "Couldn't find NXEA" unless operator
    operator.route_operators.each do |route_operator|
      route = route_operator.route
      RouteOperator.create!(:operator => new_operator, :route => route)
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
