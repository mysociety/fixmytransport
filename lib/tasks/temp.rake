require File.dirname(__FILE__) +  '/data_loader'

namespace :temp do

  desc 'Fix stations with codes starting 650' 
  task :fix_650_station_codes => :environment do 
    StopArea.find_each(:conditions => "area_type = 'GRLS' and code like '650%%'") do |station|
      puts "#{station.name} #{station.id}"
      if !station.routes.empty?
        raise "station #{station.name} has routes"
      end
      station.area_type = 'GCLS'
      station.save!
    end
  end
  
  desc 'Remove new campaign'
  task :remove_new_campaign => :environment do
    unless ENV['PROBLEM_ID']
      puts ''
      puts 'Usage: Specify a problem ID'
      puts ''
      exit 0
    end
    problem_id = ENV['PROBLEM_ID']
    problem = Problem.find(problem_id)
    unless problem.campaign
      puts "No campaign for problem #{problem.id}"
      exit 0
    end
    unless problem.campaign.status == :new
      puts "Campaign #{problem.campaign.id} is not new"
      exit 0
    end
    puts "About to destroy campaign #{problem.campaign.id} for problem #{problem.id} : #{problem.subject}"
    if ENV['CONFIRM']
      problem.campaign.campaign_events.destroy_all
      problem.campaign.destroy
      problem.assignments.each do |assignment|
        assignment.campaign_id = nil
        assignment.save!
      end
      problem.campaign_id = nil
      problem.confirmed_at = Time.now
      problem.save!
      puts "Destroyed."
    end
  end

end