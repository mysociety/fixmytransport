require File.dirname(__FILE__) +  '/data_loader'
require File.dirname(__FILE__) +  '/../fixmytransport/geo_functions'

namespace :temp do
  
  desc 'Move data about who is responsible for a problem to another table'
  task :populate_responsibilities => :environment do
    Problem.find_each do |problem|
      responsible_organizations = []
      if problem.location.operators_responsible? && problem.operator
        responsible_organizations << problem.operator
      else
        responsible_organizations = problem.location.responsible_organizations
      end
      responsible_organizations.each do |organization|
        problem.responsibilities.create(:organization_type => organization.class.to_s,
                                        :organization_id => organization.id)
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