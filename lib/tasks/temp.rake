require File.dirname(__FILE__) +  '/data_loader'
require File.dirname(__FILE__) +  '/../fixmytransport/geo_functions'

namespace :temp do

  desc 'Populate the Isle of Wight bus stop and bus station operators'
  task :populate_isle_of_wight_operators => :environment do 
    southern_vectis = Operator.find_by_name('Southern Vectis')
    isle_of_wight = AdminArea.find_by_name('Isle of Wight')
    isle_of_wight.localities.each do |locality|
      locality.stops.each do |stop|
        stop.stop_operators.create!(:operator => southern_vectis)
      end
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