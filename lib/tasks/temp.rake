require File.dirname(__FILE__) +  '/data_loader'
require File.dirname(__FILE__) +  '/../fixmytransport/geo_functions'

namespace :temp do

  desc "Deliver a one-off followup email to people who made a campaign but didn't add details"
  task :deliver_one_off_campaign_followups => :environment do 
    # get campaigns with :new status that have been created in the last couple of weeks
    campaigns = Campaign.find(:all, :conditions => ['status_code = ? 
                                                     AND created_at >= ?
                                                     AND created_at <= ?
                                                     and title is null', 0, Time.now - 2.weeks, Time.now - 1.day])
    campaigns.each do |campaign|
      ProblemMailer.deliver_one_off_followup_for_new_campaigns(campaign.initiator, campaign.problem)
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
  
end