require File.dirname(__FILE__) +  '/data_loader'

namespace :temp do
  
  desc 'Backfill slugs for campaigns from the subdomains' 
  task :backfill_campaign_slugs => :environment do 
    Campaign.find_each(:conditions => ['subdomain is not null']) do |campaign|
      campaign.slugs.create :name => campaign.subdomain, :sluggable => campaign
    end
  end
  
  desc 'Set confirmed_password flag to true on all users where registered flag is true'
  task :set_confirmed_password => :environment do 
    User.find_each(:conditions => ['registered = ?', true]) do |user|
      user.confirmed_password = true
      user.save_without_session_maintenance
    end
  end

  desc 'Recache route descriptions for train routes'
  task :recache_route_descriptions => :environment do 
    Route.find_each(:conditions => ['transport_mode_id = 6']) do |route|
      route.save!
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
  
end

