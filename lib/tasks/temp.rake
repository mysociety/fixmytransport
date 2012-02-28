namespace :temp do
  
  desc 'Set the data generation on existing tables'
  task :set_data_generation => :environment do 
    # DataGeneration.create!(:name => "Initial data load", :description => 'Data load from NPTDR on site creation')
    Region.connection.execute("update regions set generation_low = 1, generation_high = 1")
    AdminArea.connection.execute("update admin_areas set generation_low = 1, generation_high = 1")
    District.connection.execute("update districts set generation_low = 1, generation_high = 1")
    Locality.connection.execute("update localities set generation_low = 1, generation_high = 1")
    Slug.connection.execute("update slugs set generation_low = 1, generation_high = 1")
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

end
