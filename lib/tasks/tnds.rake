require File.dirname(__FILE__) +  '/data_loader'

namespace :tnds do

  namespace :load do 
    
    desc 'Loads routes from a set of TransXchange files specified by a glob passe as GLOB=glob.
          Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1'
    task :routes => :environment do 
      check_for_dir
      verbose = check_verbose
      dryrun = check_dryrun
      puts "Loading routes from #{ENV['DIR']}..."
      Route.paper_trail_off
      RouteSegment.paper_trail_off
      RouteOperator.paper_trail_off
      JourneyPattern.paper_trail_off
      parser = Parsers::TransxchangeParser.new
      file_glob = File.join(ENV['DIR'], "*.xml")
      index_file = File.join(ENV['DIR'], 'TravelineNationalDataSetFilesList.txt')
      parser.parse_all_tnds_routes(file_glob, index_file, verbose) do |route|
        merged = false
        puts "route"
        route.route_sources.each do |route_source|
          existing = Route.find(:all, :conditions => ['route_sources.service_code = ?
                                                       AND route_sources.operator_code = ?
                                                       AND route_sources.region_id = ?',
                                                       route_source.service_code, 
                                                       route_source.operator_code, 
                                                       route_source.region],
                                      :include => :route_sources)
          if existing.size > 1 
            raise "More than one existing route for matching source criteria"
          end
          if (!existing.empty?) && (!merged)
            if !dryrun
              puts "merging"
              Route.merge_duplicate_route(route, existing.first)
            end
            merged = true
          end
        end
        if (!dryrun) && (!merged)
          puts "saving"
          route.save!
        end
      end
      Route.paper_trail_on
      RouteSegment.paper_trail_on
      RouteOperator.paper_trail_on
      JourneyPattern.paper_trail_on
    end
  
  end
  
  namespace :update do
    
    desc 'Updates routes from a set of TransXchange files in a dir specified as DIR=dirname to
          generation id specified as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0
          is specified. Verbose flag set by VERBOSE=1'
    task :routes => :environment do 
      load_instances_in_generation(Route, Parsers::TransxchangeParser)
    end
    
  end
  
end