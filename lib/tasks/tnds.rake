require File.dirname(__FILE__) +  '/data_loader'

namespace :tnds do

  namespace :load do

    desc 'Loads routes from a set of TransXchange files in a directory passed as DIR=dir.
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
      parser.parse_all_tnds_routes(file_glob, index_file, verbose, skip_loaded=false) do |route|
        merged = false
        puts "Parsed route #{route.number}" if verbose
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
            if verbose
              puts "merging with existing route id: #{existing.first.id}, number #{existing.first.number}" 
            end
            if !dryrun
              Route.merge_duplicate_route(route, existing.first)
            end
            merged = true
          end
        end
        puts "saving" if verbose
        if (!dryrun) && (!merged)
          route.save!
          puts "saved as #{route.id}" if verbose
        end
      end
      Route.paper_trail_on
      RouteSegment.paper_trail_on
      RouteOperator.paper_trail_on
      JourneyPattern.paper_trail_on
    end

  end

  # Try and identify a route that matches this one in the previous data generation
  def find_previous_for_route(route, verbose, dryrun)
    operators = route.operators.map{ |operator| operator.name }.join(", ")
    puts "Route id: #{route.id}, number: #{route.number}, operators: #{operators}" if verbose
    # Call these functions on the route to make sure stops and stop areas are queried
    # before we enter the find_all_by_number_and_common_stop method, which is scoped to
    # the previous data generation
    route.stop_area_codes
    route.stop_codes
    
    previous = nil
    FixMyTransport::DataGenerations.in_generation(PREVIOUS_GENERATION) do
      previous = Route.find_existing_routes(route)
    end
    puts "Found #{previous.size} routes" if verbose
    if previous.size > 1
      route_ids = previous.map{ |previous_route| previous_route.id }.join(", ")
      raise "Matched more than one previous route! #{route_ids}"
    end
    previous.each do |previous_route|
      puts "Matched to route id: #{previous_route.id}, number #{previous_route.number}" if verbose
      route.previous_id = previous.first.id
      if ! dryrun
        puts "Saving route" if verbose
        route.save!
      end
    end
  end
  
  namespace :update do

    desc 'Attempts to match routes in the current generation with routes in the previous
          generation. Call with ROUTE_ID=id to specify a single route to try and match.
          Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1'
    task :find_previous_routes => :environment do
      verbose = check_verbose
      dryrun = check_dryrun
      if ENV['ROUTE_ID']
        route = Route.find(ENV['ROUTE_ID'])
        find_previous_for_route(route, verbose, dryrun)
      else
        conditions = { :conditions => ['routes.previous_id IS NULL
                                       AND route_operators.id IS NOT NULL'],
                       :include => :route_operators }
        Route.find_each(conditions) do |route|
          find_previous_for_route(route, verbose, dryrun)
        end
      end
    end

  end

end