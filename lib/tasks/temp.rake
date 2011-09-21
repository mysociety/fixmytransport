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
        responsible_organizations =  problem.location.responsible_organizations
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
  
  desc 'Fix stations that are listed as belonging to each other'
  task :fix_station_links => :environment do 
    relationships = {'910GDEPDENE' => ['910GDORKING', 'South West Trains'],
                     '910GWSORAER' => ['910GWINDSEC', 'South West Trains'],
                     '910GBCSTRTN' => ['910GBCSTN', 'Chiltern Railways'],
                     '910GASHVALE' => ['910GNTHCAMP', 'South West Trains' ] }
    
    # Delete the StopAreaLink that says that one station is part of another
    relationships.each do |child_code, data|
      parent_code, operator_name = data
      stop_area = StopArea.find_by_code(child_code)
      links = stop_area.links_as_descendant
      links.each do |link|
        if link.ancestor == StopArea.find_by_code(parent_code)
          if link.destroyable?
            link.destroy
          end
        end
      end
      stop_area.stop_area_operators.create!(:operator => Operator.find_by_name(operator_name))
      station_types = StopType.station_part_types_to_station_types
      stop_area.stops.each do |stop|
        
        next unless StopType.station_part_types.include?(stop.stop_type)
        puts "Updating journey patterns for #{stop.name}"
        station_stop_area = stop.root_stop_area(station_types[stop.stop_type])
        puts station_stop_area.name
        stop.route_segments_as_from_stop.each do |route_segment|
          route_segment.from_stop_area_id = station_stop_area.id
          route_segment.save!
        end
        stop.route_segments_as_to_stop.each do |route_segment|
          route_segment.to_stop_area_id = station_stop_area.id
          route_segment.save!
        end
        
      end
    end
  end
  
  desc 'Fix manual ferry stops'
  task :fix_manual_ferry_stops => :environment do 
    riverside = Stop.find_by_other_code('9300RQP')
    # correct the name and coords
    riverside.common_name = 'Riverside Quarter Pier'
    riverside.lat = 51.46277
    riverside.lon = -0.19901
    # associate to the correct terminal
    riverside_terminal = StopArea.find_by_code('930GWRQ')
    riverside.stop_area_memberships.build(:stop_area => riverside_terminal)
    # update the locality
    riverside.locality = Locality.find_by_name('Wandsworth')
    
    riverside.save!
    riverside.routes.each do |route|
      puts route.id
      route.route_segments.each do |segment|
        segment.from_stop_area = nil
        segment.to_stop_area = nil
        segment.save!
      end
      route.save!
    end
    
    woolwich = Stop.find_by_other_code('9300WAP')
    # correct the name and coords
    woolwich.common_name = 'Woolwich Arsenal Pier'
    woolwich.lat = 51.495858
    woolwich.lon = 0.070982
    # associate to correct terminal
    woolwich.stop_area_memberships.clear
    woolwich_terminal = StopArea.find_by_code('930GWAS')
    woolwich.stop_area_memberships.build(:stop_area => woolwich_terminal)
    # update the locality
    woolwich.locality = Locality.find_by_name("Woolwich")
    
    woolwich.save!
    woolwich.routes.each do |route|
      puts route.id 
      route.route_segments.each do |segment|
        segment.from_stop_area = nil
        segment.to_stop_area = nil
        segment.save!
      end
      route.save!
    end
        
  end
  
end