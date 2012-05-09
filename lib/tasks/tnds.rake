require File.dirname(__FILE__) +  '/data_loader'

namespace :tnds do

  def operators_from_info(short_name, license_name, trading_name, verbose)
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
    puts "Loose query found #{operators.size} #{operators.inspect}" if verbose
    # if loose query is ambiguous, try without short name
    query_conditions = []
    params = []
    if (operators.size > 1) && (license_name || trading_name)
      puts "Trying stricter" if verbose
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
      puts "Strict query found #{operators.size} operators" if verbose
    end
    operators
  end

  namespace :preload do

    desc 'Loads data from a file produced by tnds:preload:list_unmatched_operators and loads missing
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
      outfile = File.open("data/operators/missing_#{Time.now.to_date.to_s(:db)}_with_fixes.tsv", 'w')
      headers = ['Short name',
                 'Trading name',
                 'Name on license',
                 'Code',
                 'Problem',
                 'Region',
                 'File',
                 'Suggested NOC match',
                 'Suggested NOC match name',
                 'Suggested NOC action']
      outfile.write(headers.join("\t")+"\n")
      manual_matches = { 'First in Greater Manchester' => 'First Manchester',
                         'Grovesnor Coaches' => 'Grosvenor Coaches',
                         'TC Minicoaches' => 'T C Minicoaches',
                         'Fletchers Coaches' => "Fletcher's Coaches",
                         'Select Bus & Coach Servi' => 'Select Bus & Coach',
                         'Landmark Coaches' => 'Landmark  Coaches',
                         'Romney Hythe and Dymchu' => 'Romney Hythe & Dymchurch Light Railway',
                         'Sovereign Coaches' => 'Sovereign',
                         'TM Travel' => 'T M Travel Ltd',
                         'First in London' => 'First (in the London area)',
                         'First in Berkshire & Th' => 'First (in the Thames Valley)',
                         'First in Calderdale & H' => 'First Huddersfield',
                         'First in Essex' => 'First (in the Essex area)',
                         'First in Greater Manche' => 'First Manchester',
                         'First in Suffolk & Norf' => 'First Eastern Counties',
                         'Yourbus' => 'Your Bus',
                         'Andybus &amp; Coach' => 'Andybus & Coach Ltd',
                         'AJ & NM Carr' => 'A J & N M Carr',
                         'AP Travel' => 'AP Travel Ltd',
                         'Ad&apos;Rains Psv' => "AD'RAINS PSV",
                         'Anitas Coaches' => "Anita's Coaches",
                         'B&NES' => 'Bath & North East Somerset Council',
                         'Bath Bus Company' => 'Bath Bus Co Ltd',
                         'Briggs Coach Hire' => 'Briggs Coaches',
                         'Centrebus (Beds Herts &' => 'Centrebus (Beds & Herts area)',
                         'Eagles Coaches' => 'Eagle Coaches',
                         'First in Bristol, Bath & the West' => 'First in Bristol',
                         'Green Line (operated by Arriva the Shires)' => 'Green Line (operated by Arriva the Shires & Essex)',
                         'Green Line (operated by First in Berkshire)' => 'Green Line (operated by First - Thames Valley)',
                         'H.C.Chambers & Son' => 'H C Chambers & Son',
                         'Holloways Coaches' => 'Holloway Coaches',
                         'Kimes Coaches' => 'Kimes',
                         'P&O Ferries' => 'P & O Ferries',
                         'RH Transport' => 'R H Transport',
                         "Safford's Coaches" => 'Safford Coaches',
                         }
      FasterCSV.parse(tsv_data, tsv_options) do |row|
        region = row['Region']
        operator_code = row['Code']
        short_name = row['Short name']
        trading_name = row['Trading name']
        license_name = row['Name on license']
        problem = row['Problem']
        file = row['File']

        raise "No short name in line #{row.inspect}" if short_name.blank?
        short_name.strip!
        trading_name.strip! if trading_name
        license_name.strip! if license_name

        operator_info = { :short_name => short_name,
                          :trading_name => trading_name,
                          :license_name => license_name }
        if !new_data[operator_info]
          puts "Looking for #{short_name} #{trading_name} #{license_name}" if verbose
          if manual_name = (manual_matches[short_name] || manual_matches[trading_name])
            operators = Operator.find(:all, :conditions => ['lower(name) = ?', manual_name.downcase])
          else
            operators = operators_from_info(short_name, license_name, trading_name, verbose)
            if operators.empty?
              short_name_canonical = short_name.gsub('First in', 'First')
              short_name_canonical = short_name_canonical.gsub('.', '')
              short_name_canonical = short_name_canonical.gsub('Stagecoach', 'Stagecoach in')
              short_name_canonical = short_name_canonical.gsub('&amp;', '&')
              if short_name_canonical != short_name
                operators = Operator.find(:all, :conditions => ['lower(name) = ?', short_name_canonical.downcase])
              end
             end
          end
          if operators.size == 1
            # puts "Found operator #{operators.first.name} for #{short_name}"
            operator_info[:match] = operators.first
          end


          new_data[operator_info] = {}
        end
        if !new_data[operator_info][region]
          new_data[operator_info][region] = []
        end
        new_data[operator_info][region] << operator_code unless new_data[operator_info][region].include?(operator_code)
        matched_code = operator_info[:match].nil? ? '' : operator_info[:match].noc_code
        matched_name = operator_info[:match].nil? ? '' : operator_info[:match].name
        if matched_code.blank?
          suggested_noc_action = 'New NOC record needed'
        else
          suggested_noc_action = "Add code in region for NOC match"
        end
        outfile.write([short_name,
                       trading_name,
                       license_name,
                       operator_code,
                       problem,
                       region,
                       file,
                       matched_code,
                       matched_name,
                       suggested_noc_action].join("\t")+"\n")
      end
      outfile.close()
      existing_operators = 0
      new_operators = 0
      new_operator_names = []
      new_data.each do |operator_info, region_data|
        if operator_info[:match]
          existing_operators += 1
          operator = operator_info[:match]
        else
          operator = Operator.new( :short_name => operator_info[:short_name])
          if !operator_info[:trading_name].blank?
            operator.name = operator_info[:trading_name]
          else
            operator.name = operator_info[:short_name]
          end
          if !operator_info[:license_name].blank?
            operator.vosa_license_name = operator_info[:license_name]
          end
          new_operator_names << "#{operator.short_name} #{operator.name} #{operator.vosa_license_name}"
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
        if !operator.valid?
          puts "ERROR: Operator is invalid:"
          puts operator.inspect
          puts operator.errors.full_messages.join("\n")
          exit(1)
        end
        if !dryrun
          operator.save!
        end
      end
      puts "New operators: #{new_operators}"
      puts "Existing operators: #{existing_operators}"
      new_operator_names.sort!
      new_operator_names.each do |new_name|
        puts new_name if verbose
      end
    end

    desc 'Produce a list of unmatched operator information from a set of TransXchange
          files in a directory passed as DIR=dir. Verbose flag set by VERBOSE=1.
          To re-load routes from files that have already been loaded in this data generation,
          supply SKIP_LOADED=0. Otherwise these files will be ignored.
          Specify FIND_REGION_BY=directory if regions need to be inferred from directories.'
    task :list_unmatched_operators => :environment do
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
    # Call these functions on the route to make sure stops, stop areas and route operators are queried
    # before we enter the find_all_by_number_and_common_stop method, which is scoped to
    # the previous data generation
    route.stop_area_codes
    route.stop_codes
    route.route_operators(force_reload=true)
    previous = nil
    FixMyTransport::DataGenerations.in_generation(PREVIOUS_GENERATION) do
      previous = Route.find_existing_routes(route)
      puts "Found #{previous.size} routes" if verbose
      if previous.size == 0
        previous = Route.find_existing_routes(route, { :skip_operator_comparison => true,
                                                       :require_match_fraction => 0.8 })
        puts "Found #{previous.size} routes, on complete stop match without operators" if verbose
      end
    end


    if previous.size > 1
      # discard any of the routes that have other operators
      previous = previous.delete_if do |previous_route|
        other_operators = previous_route.operators.any?{ |operator| ! route.operators.include?(operator) }
        if other_operators
          puts "Rejecting #{previous_route.id} as it has other operators" if verbose
        end
        other_operators
      end
    end
    if previous.size > 1
      route_ids = previous.map{ |previous_route| previous_route.id }.join(", ")
      puts "Matched more than one previous route! #{route_ids}"
      return
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
        train_mode = TransportMode.find_by_name('Train')
        conditions = { :conditions => ['routes.previous_id IS NULL and transport_mode_id != ?
                                        AND route_operators.id IS NOT NULL', train_mode],
                       :include => :route_operators }
        Route.find_each(conditions) do |route|
          puts "Looking for #{route.number}" if verbose
          find_previous_for_route(route, verbose, dryrun)
        end
      end
    end

    desc 'Deletes all route associated data for a particular generation, defined as
          GENERATION=generation.'
    task :clear_routes => :environment do
      generation = check_for_generation()
      RouteSource.connection.execute("DELETE FROM route_sources
                                      WHERE route_id in
                                      (SELECT id
                                       FROM routes
                                       WHERE generation_low = #{generation})")
      RouteLocality.connection.execute("DELETE FROM route_localities
                                        WHERE route_id in
                                        (SELECT id
                                         FROM routes
                                         WHERE generation_low = #{generation})")
      Route.connection.execute("DELETE FROM routes
                                WHERE generation_low = #{generation}")
      RouteSegment.connection.execute("DELETE FROM route_segments
                                       WHERE generation_low = #{generation}")

      RouteOperator.connection.execute("DELETE FROM route_operators
                                        WHERE generation_low = #{generation}")
      JourneyPattern.connection.execute("DELETE FROM journey_patterns
                                         WHERE generation_low = #{generation}")
      Route.connection.execute("DELETE FROM slugs where sluggable_type = 'Route'
                                AND generation_low = #{generation}")

    end

    def clone_in_new_generation(old_instance)
      new_instance = old_instance.clone
      new_instance.generation_high = CURRENT_GENERATION
      new_instance.generation_low = CURRENT_GENERATION
      new_instance.previous_id = old_instance.id
      new_instance.persistent_id = old_instance.persistent_id
      return new_instance
    end

    def find_successor(old_instance, model_class, relationship)
      old_identifier = old_instance.send(relationship)
      new_related_instance = model_class.find_successor(old_identifier)
      raise "Can't find successor to #{model_class} #{old_identifier}" unless new_related_instance
      return new_related_instance
    end

    desc 'Promote train routes (which are not included in TNDS) to the current generation.
          Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1'
    task :train_routes => :environment do
      verbose = check_verbose
      dryrun = check_dryrun
      Route.paper_trail_off
      RouteSegment.paper_trail_off
      RouteOperator.paper_trail_off
      JourneyPattern.paper_trail_off

      Route.in_generation(PREVIOUS_GENERATION) do
        train_mode = TransportMode.find_by_name('Train')
        Route.find_each(:conditions => ["transport_mode_id = ?", train_mode]) do |route|

          puts "Updating #{route.name} #{route.id} to generation #{CURRENT_GENERATION}" if verbose
          new_gen_route = clone_in_new_generation(route)
          new_gen_route.region = find_successor(route, Region, :region_id)
          journey_patterns = []
          JourneyPattern.in_any_generation do
            journey_patterns = route.journey_patterns(force_reload=true)
          end
          journey_patterns.each do |journey_pattern|
            new_attributes = clone_in_new_generation(journey_pattern).attributes
            new_gen_journey_pattern = new_gen_route.journey_patterns.build(new_attributes)
            new_gen_journey_pattern.route = new_gen_route
            route_segments = []
            RouteSegment.in_any_generation do
              route_segments = journey_pattern.route_segments(force_reload=true)
            end
            route_segments.each do |route_segment|
              new_attributes = clone_in_new_generation(route_segment).attributes
              new_gen_route_segment = new_gen_journey_pattern.route_segments.build(new_attributes)
              new_gen_route_segment.route = new_gen_route
              new_gen_route_segment.from_stop = find_successor(route_segment, Stop, :from_stop_id)
              new_gen_route_segment.to_stop = find_successor(route_segment, Stop, :to_stop_id)
              if route_segment.from_stop_area_id
                new_gen_route_segment.from_stop_area = find_successor(route_segment, StopArea, :from_stop_area_id)
              end
              if route_segment.to_stop_area_id
                new_gen_route_segment.to_stop_area = find_successor(route_segment, StopArea, :to_stop_area_id)
              end
            end
          end
          route_operators = []
          RouteOperator.in_any_generation do
            route_operators = route.route_operators(force_reload=true)
          end
          route_operators.each do |route_operator|
            new_attributes = clone_in_new_generation(route_operator).attributes
            new_route_operator = new_gen_route.route_operators.build(new_attributes)
            new_route_operator.operator = find_successor(route_operator, Operator, :operator_id)
          end

          route_source_admin_areas = []
          RouteSourceAdminArea.in_any_generation do
            route_source_admin_areas = route.route_source_admin_areas(force_reload=true)
          end
          route_source_admin_areas.each do |route_source_admin_area|
            new_attributes = clone_in_new_generation(route_source_admin_area).attributes
            new_route_source_admin_area = new_gen_route.route_source_admin_areas.build(new_attributes)
            if route_source_admin_area.source_admin_area_id
              new_route_source_admin_area.source_admin_area = find_successor(route_source_admin_area, AdminArea, :source_admin_area_id)
            end
          end

          if !new_gen_route.valid?
            puts "ERROR: Route is invalid:"
            puts new_gen_route.inspect
            puts new_gen_route.errors.full_messages.join("\n")
            exit(1)
          end
          if !dryrun
            new_gen_route.save!
          end
        end
      end
      Route.paper_trail_on
      RouteSegment.paper_trail_on
      RouteOperator.paper_trail_on
      JourneyPattern.paper_trail_on
    end
  end

end