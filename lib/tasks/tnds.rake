require File.dirname(__FILE__) +  '/data_loader'

namespace :tnds do

  def operators_from_info(short_name, license_name, trading_name)
    query_conditions = [ 'lower(name) = ?', 'lower(name) like ?', 'lower(short_name) = ?']
    params = [ short_name.downcase, "#{short_name}%".downcase, short_name.downcase ]
    if license_name
      query_conditions << 'lower(vosa_license_name) = ?'
      params << license_name.downcase
    end
    if trading_name
      query_conditions << 'lower(name) = ?'
      params << trading_name.downcase
    end
    query = query_conditions.join(" OR ")
    conditions =  [query] + params
    operators = Operator.find(:all, :conditions => conditions)
  end

  namespace :preload do

    desc 'Loads data from a file produced by tnds:preload:unmatched_operators and loads missing
          operator codes and operators into the database. Accepts a file as FILE=file.
          Verbose flag set by VERBOSE=1. Runs in dryrun mode unless DRYRUN=0 is specified'
    task :load_unmatched_operators => :environment do
      tsv_options = { :quote_char => '"',
                      :col_sep => "\t",
                      :row_sep =>:auto,
                      :return_headers => false,
                      :headers => :first_row,
                      :encoding => 'N' }
      check_for_file
      verbose = check_verbose
      dryrun = check_dryrun
      tsv_data = File.read(ENV['FILE'])
      new_data = {}

      manual_matches = { 'First in Greater Manchester' => 'First Manchester',
                         'Grovesnor Coaches' => 'Grosvenor Coaches',
                         'TC Minicoaches' => 'T C Minicoaches'}
      FasterCSV.parse(tsv_data, tsv_options) do |row|
        region = row['Region']
        operator_code = row['Code']
        short_name = row['Short name']
        trading_name = row['Trading name']
        license_name = row['Name on license']
        problem = row['Problem']

        raise "No short name in line #{row.inspect}" if short_name.blank?
        if problem == "ambiguous"
          next
        end

        operator_info = { :short_name => short_name,
                          :trading_name => trading_name,
                          :license_name => license_name }

        operators = operators_from_info(short_name, license_name, trading_name)
        if operators.empty?
          if manual_name = manual_matches[short_name]
            operators = Operator.find(:all, :conditions => ['lower(name) = ?', manual_name.downcase])
          end
          if operators.empty?
            short_name_canonical = short_name.gsub('First in', 'First')
            if short_name_canonical != short_name
              operators = operators_from_info(short_name_canonical, license_name, trading_name)
            end
          end
        end
        if operators.size == 1
          # puts "Found operator #{operators.first.name} for #{short_name}"
          operator_info[:match] = operators.first
        end

        if !new_data[operator_info]
          new_data[operator_info] = {}
        end
        if !new_data[operator_info][region]
          new_data[operator_info][region] = []
        end
        new_data[operator_info][region] << operator_code unless new_data[operator_info][region].include?(operator_code)
      end

      existing_operators = 0
      new_operators = 0
      new_data.each do |operator_info, region_data|
        if operator_info[:match]
          existing_operators += 1
          operator = operator_info[:match]
        else
          operator = Operator.new( :short_name => operator_info[:short_name])
          if !operator_info[:trading_name].blank?
            operator.name = operator_info[:trading_name]
          end
          if !operator_info[:license_name].blank?
            operator.vosa_license_name = operator_info[:license_name]
          end
          puts operator.inspect
          new_operators += 1
        end
        region_data.each do |region_name, operator_codes|
          region = Region.find_by_name(region_name)
          raise "No region found for name #{region_name}" unless region
          operator_codes.each do |operator_code|
            operator.operator_codes.build(:region => region, :code => operator_code )
            # puts "#{region_name} #{operator_code}"
          end
        end
        if !dryrun
          operator.save!
        end
      end
      puts "New operators: #{new_operators}"
      puts "Existing operators: #{existing_operators}"
    end

    desc 'Produce a list of unmatched operator information from a set of TransXchange
          files in a directory passed as DIR=dir. Verbose flag set by VERBOSE=1.
          To re-load routes from files that have already been loaded in this data generation,
          supply SKIP_LOADED=0. Otherwise these files will be ignored.
          Specify FIND_REGION_BY=directory if regions need to be inferred from directories.'
    task :unmatched_operators => :environment do
      check_for_dir
      verbose = check_verbose
      skip_loaded = true
      skip_loaded = false if ENV['SKIP_LOADED'] == '0'
      if ENV['FIND_REGION_BY'] == 'directory'
        regions_as = :directories
      else
        regions_as = :index
      end
      parser = Parsers::TransxchangeParser.new
      outfile = File.open("data/operators/missing_#{Time.now.to_date.to_s(:db)}.tsv", 'w')
      headers = ['Short name', 'Trading name', 'Name on license', 'Code', 'Problem', 'Region', 'File']
      outfile.write(headers.join("\t")+"\n")
      file_glob = File.join(ENV['DIR'], "**/*.xml")
      index_file = File.join(ENV['DIR'], 'TravelineNationalDataSetFilesList.txt')
      lines = 0
      parser.parse_all_tnds_routes(file_glob, index_file, verbose, skip_loaded, regions_as) do |route|
        if route.route_operators.length != 1
          lines += 1
          row = [route.operator_info[:short_name],
                 route.operator_info[:trading_name],
                 route.operator_info[:name_on_license],
                 route.operator_info[:code],
                 route.route_operators.length > 1 ? 'ambiguous' : 'not found',
                 route.region.name,
                 route.route_sources.first.filename]
          outfile.write(row.join("\t")+"\n")
          if lines % 10 == 0
            outfile.flush
          end
        end
      end
      outfile.close()
    end
  end

  namespace :load do

    desc 'Loads routes from a set of TransXchange files in a directory passed as DIR=dir.
          Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1.
          To re-load routes from files that have already been loaded in this data generation,
          supply SKIP_LOADED=0. Otherwise these files will be ignored.
          Specify FIND_REGION_BY=directory if regions need to be inferred from directories.'
    task :routes => :environment do
      check_for_dir
      verbose = check_verbose
      dryrun = check_dryrun
      skip_loaded = true
      skip_loaded = false if ENV['SKIP_LOADED'] == '0'
      puts "Loading routes from #{ENV['DIR']}..."
      if ENV['FIND_REGION_BY'] == 'directory'
        regions_as = :directories
      else
        regions_as = :index
      end
      Route.paper_trail_off
      RouteSegment.paper_trail_off
      RouteOperator.paper_trail_off
      JourneyPattern.paper_trail_off
      parser = Parsers::TransxchangeParser.new
      file_glob = File.join(ENV['DIR'], "**/*.xml")
      index_file = File.join(ENV['DIR'], 'TravelineNationalDataSetFilesList.txt')
      parser.parse_all_tnds_routes(file_glob, index_file, verbose, skip_loaded=false, regions_as) do |route|
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