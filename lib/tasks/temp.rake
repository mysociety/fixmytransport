require File.dirname(__FILE__) +  '/data_loader'

namespace :temp do

  desc 'Set confirmed_password flag to true on all users where registered flag is true'
  task :set_confirmed_password => :environment do
    User.find_each(:conditions => ['registered = ?', true]) do |user|
      user.confirmed_password = true
      user.save_without_session_maintenance
    end
  end

  desc 'Set campaign on assignments'
  task :set_campaign_on_assignments => :environment do
    Problem.find_each(:conditions => ['campaign_id is not null']) do |problem|
      problem.assignments.each do |assignment|
        assignment.update_attribute('campaign_id', problem.campaign_id)
      end
    end
  end

  desc 'Add stop and stop area cached descriptions'
  task :add_stop_and_stop_area_cached_descriptions => :environment do
    puts "stops"
    Stop.find_each do |stop|
      stop.save!
      print '.'
    end
    puts "stop areas"
    StopArea.find_each do |stop_area|
      stop_area.save!
      print '.'
    end
  end

  desc 'Add some operators that had ambiguous codes'
  task :add_operators_for_ambiguous_codes => :environment do
    # BL - Badgerline now First Somerset & Avon
    # FC00 - In Wales will be First Cymru
    # MN - In London is Arriva London
    # KIM - In East Midlands, Kimes
    # ML - In London, Metroline
    # FL - First Leeds
    # SIH - In East Anglia is Stagecoach in Huntingdonshire 
    # AM - In the East Midlands is Arriva Midlands
    # IF - East London in London 
    mappings = { 'BL' => 'First Somerset & Avon',
                 'FC00' => 'First Cymru', 
                 'MN' => 'Arriva London',
                 'KIM' => 'Kimes',
                 'ML' => 'Metroline Travel', 
                 'FL' => 'First Leeds',
                 # 'FCH' => 'First in Calderdale and Huddersfield', # not all of them anymore
                 'SIF' => 'Stagecoach in Huntingdonshire', 
                 'YRB' => 'First Bradford',
                 'AM' => 'Arriva Midlands',
                 'IF' => 'East London Bus & Coach' }
    mappings.each do |code, operator_name|
      operator = Operator.find_by_name(operator_name)
      routes = Route.find(:all, :conditions => ['operator_code = ?
                                                 AND id not in (SELECT route_id FROM route_operators)', code])
      routes.each do |route|
        puts "#{operator.name} #{route.description}"
        route.route_operators.create!(:operator => operator)
      end
    end
  end

  desc 'Cache route descriptions'
  task :cache_route_descriptions => :environment do
    Route.find_each(:conditions => ['cached_description is null']) do |route|
      Route.connection.execute("UPDATE routes set cached_description = #{Route.connection.quote(route.description)} where id = #{route.id}" )
      puts '.'
    end
  end
  
  desc 'Cache route short names'
  task :cache_route_short_names => :environment do
    Route.find_each(:conditions => ['cached_short_name is null']) do |route|
      Route.connection.execute("UPDATE routes set cached_short_name = #{Route.connection.quote(route.short_name)} where id = #{route.id}" )
      puts '.'
    end
  end
  
  desc 'Cache route areas'
  task :cache_route_areas => :environment do
    Route.find_each(:conditions => ['cached_area is null']) do |route|
      Route.connection.execute("UPDATE routes set cached_area = #{Route.connection.quote(route.area)} where id = #{route.id}" )
      puts '.'
    end
  end

  desc 'Cache default journeys for routes'
  task :cache_default_journeys => :environment do
    Route.find_each(:conditions => ['default_journey_id is null']) do |route|
      route.generate_default_journey
      if route.default_journey
        Route.connection.execute("UPDATE routes set default_journey_id = #{route.default_journey.id} where id = #{route.id}" )
      end
    end
  end

end

