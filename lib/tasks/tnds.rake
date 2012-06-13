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
    operators = Operator.current.find(:all, :conditions => conditions)
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
      operators = Operator.current.find(:all, :conditions => conditions)
      puts "Strict query found #{operators.size} operators" if verbose
    end
    operators
  end

  namespace :preload do

    desc 'Loads data from a file produced by tnds:preload:list_unmatched_operators and loads missing
          operator codes and operators into the database. Accepts a file as FILE=file.
          Verbose flag set by VERBOSE=1. Runs in dryrun mode unless DRYRUN=0 is specified.
          Produces an output file of suggested actions with respect to the NOC database.'
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
            operators = Operator.current.find(:all, :conditions => ['lower(name) = ?', manual_name.downcase])
          else
            operators = operators_from_info(short_name, license_name, trading_name, verbose)
            if operators.empty?
              short_name_canonical = short_name.gsub('First in', 'First')
              short_name_canonical = short_name_canonical.gsub('.', '')
              short_name_canonical = short_name_canonical.gsub('Stagecoach', 'Stagecoach in')
              short_name_canonical = short_name_canonical.gsub('&amp;', '&')
              if short_name_canonical != short_name
                operators = Operator.current.find(:all, :conditions => ['lower(name) = ?',
                                                                         short_name_canonical.downcase])
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
          region = Region.current.find_by_name(region_name)
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
          To include routes from files that have already been loaded in this data generation,
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
      headers = ['NOC Code', 'Short name', 'Trading name', 'Name on license', 'Code', 'Problem', 'Region', 'File']
      outfile.write(headers.join("\t")+"\n")
      file_glob = File.join(ENV['DIR'], "**/*.xml")
      index_file = File.join(ENV['DIR'], 'TravelineNationalDataSetFilesList.txt')
      lines = 0
      parser.parse_all_tnds_routes(file_glob, index_file, verbose, skip_loaded, regions_as) do |route|
        if route.route_operators.length != 1
          lines += 1
          row = [route.operator_info[:noc_code],
                 route.operator_info[:short_name],
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

    desc "Produce a list of missing stop information from a set of TransXChange files
          in a directory passed as DIR=dir. Verbose flag set by VERBOSE=1.
          To include routes from files that have already been loaded in this data generation,
          supply SKIP_LOADED=0. Otherwise these files will be ignored.
          Specify FIND_REGION_BY=directory if regions need to be inferred from directories."
    task :list_unmatched_stops => :environment do
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
      outfile = File.open("data/stops/missing_#{Time.now.to_date.to_s(:db)}.tsv", 'w')
      headers = ['Stop Code', 'Region', 'File', 'Service Code', 'Line number']
      outfile.write(headers.join("\t")+"\n")
      file_glob = File.join(ENV['DIR'], "**/*.xml")
      index_file = File.join(ENV['DIR'], 'TravelineNationalDataSetFilesList.txt')
      lines = 0
      parser.parse_all_tnds_routes(file_glob, index_file, verbose, skip_loaded, regions_as) do |route|
        if !route.missing_stops.empty?
          route.missing_stops.each do |stop_code|
            lines += 1
            row = [stop_code,
                   route.region.name,
                   route.route_sources.first.filename,
                   route.route_sources.first.service_code,
                   route.route_sources.first.line_number]
            outfile.write(row.join("\t")+"\n")
            if lines % 10 == 0
              outfile.flush
            end
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
      PaperTrail.enabled = false
      parser = Parsers::TransxchangeParser.new
      file_glob = File.join(ENV['DIR'], "**/*.xml")
      index_file = File.join(ENV['DIR'], 'TravelineNationalDataSetFilesList.txt')
      parser.parse_all_tnds_routes(file_glob, index_file, verbose, skip_loaded=skip_loaded, regions_as) do |route|
        merged = false
        puts "Parsed route #{route.number}" if verbose
        route.route_sources.each do |route_source|
          existing = Route.find_all_current_by_service_code_operator_code_and_region(route_source.service_code,
                                                                                     route_source.operator_code,
                                                                                     route_source.region)
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
      PaperTrail.enabled = true
    end

  end

  # Try and identify a route that matches this one in the previous data generation
  def find_previous_for_route(route, verbose, dryrun)
    previous = Route.find_in_generation_by_attributes(route, PREVIOUS_GENERATION, verbose)
    if previous
      puts "Matched to route id: #{previous.id}, number #{previous.number}" if verbose

      merged = false
      existing_successor = Route.current.find_by_persistent_id(previous.persistent_id)
      if existing_successor && ! (existing_successor.id == route.id)
        puts "Merging to existing successor #{existing_successor.id}, number #{existing_successor.number}" if verbose
        if !dryrun
          Route.merge_duplicate_route(route, existing_successor)
          existing_successor.find_previous_route_operators(verbose, dryrun)
          merged = true
        end
      end

      if !merged
        route.previous_id = previous.id
        route.persistent_id = previous.persistent_id

        # find previous records for route operators
        route.find_previous_route_operators(verbose, dryrun)

        if !route.valid?
           puts "ERROR: Route is invalid:"
           puts route.inspect
           puts route.errors.full_messages.join("\n")
           exit(1)
         end

        if ! dryrun
          puts "Saving route" if verbose
          route.save!
        end
      end
    else
      puts "No match for route id: #{route.id}"
      if route.previous_id
        raise "No match for a route that previously matched"
      end
    end
  end

  namespace :update do

    desc 'Finds all the cases where more than one route in the previous generation matches
          a route in the current generation and creates merge candidates for them.
          Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1'
    task :create_merge_candidates_from_multiple_matches => :environment do
      verbose = check_verbose
      dryrun = check_dryrun

        train_mode = TransportMode.find_by_name('Train')
        conditions = { :conditions => ['routes.previous_id IS NULL
                                        AND transport_mode_id != ?
                                        AND generation_low = ?', train_mode, CURRENT_GENERATION],
                       :include => :route_operators }
        Route.find_each(conditions) do |route|
          puts "Looking for #{route.number}" if verbose
          puts "#{route.class.to_s} #{route.transport_mode.name}"
          routes = Route.find_in_generation_by_attributes(route, PREVIOUS_GENERATION, verbose, {:multiple => true})
          if routes.size > 1
            first = routes.pop
            if ! dryrun
              MergeCandidate.create!(:national_route => first, :regional_route_ids => routes.map{|route| route.id}.join("|"))
            end
          end
        end
    end


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
        conditions = { :conditions => ['transport_mode_id != ?
                                        AND route_operators.id IS NOT NULL
                                        AND routes.generation_low = ?', train_mode, CURRENT_GENERATION],
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

    desc 'Promote train routes (which are not included in TNDS) to the current generation.
          Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1'
    task :train_routes => :environment do
      verbose = check_verbose
      dryrun = check_dryrun
      PaperTrail.enabled = false

      train_mode = TransportMode.find_by_name('Train')
      Route.in_generation(PREVIOUS_GENERATION).find_each(:conditions => ["transport_mode_id = ?", train_mode]) do |route|

        puts "Updating #{route.name} #{route.id} to generation #{CURRENT_GENERATION}" if verbose
        new_gen_route = clone_in_current_generation(route)
        new_gen_route.update_association_to_current_generation(:region, verbose)
        route.journey_patterns.each do |journey_pattern|
          new_attributes = clone_in_current_generation(journey_pattern).attributes
          new_gen_journey_pattern = new_gen_route.journey_patterns.build(new_attributes)
          new_gen_journey_pattern.route = new_gen_route
          journey_pattern.route_segments.each do |route_segment|
            new_attributes = clone_in_current_generation(route_segment).attributes
            new_gen_route_segment = new_gen_journey_pattern.route_segments.build(new_attributes)
            new_gen_route_segment.route = new_gen_route
            new_gen_route_segment.update_association_to_current_generation(:from_stop, verbose)
            new_gen_route_segment.update_association_to_current_generation(:to_stop, verbose)
            if route_segment.from_stop_area_id
              new_gen_route_segment.update_association_to_current_generation(:from_stop_area, verbose)
            end
            if route_segment.to_stop_area_id
              new_gen_route_segment.update_association_to_current_generation(:to_stop_area, verbose)
            end
          end
        end
        route.route_operators.each do |route_operator|
          new_attributes = clone_in_current_generation(route_operator).attributes
          new_route_operator = new_gen_route.route_operators.build(new_attributes)
          new_route_operator.update_association_to_current_generation(:operator, verbose)
        end

        route.route_source_admin_areas.each do |route_source_admin_area|
          new_attributes = clone_in_current_generation(route_source_admin_area).attributes
          new_route_source_admin_area = new_gen_route.route_source_admin_areas.build(new_attributes)
          if route_source_admin_area.source_admin_area_id
            new_route_source_admin_area.update_association_to_current_generation(:source_admin_area, verbose)
          end
        end

        route.route_sub_routes.each do |route_sub_route|
          sub_route = SubRoute.find_in_generation(route_sub_route.sub_route, CURRENT_GENERATION)
          if ! sub_route
            sub_route = clone_in_current_generation(route_sub_route.sub_route)
            if !sub_route.valid?
              puts "ERROR: Sub route is invalid:"
              puts sub_route.inspect
              puts sub_route.errors.full_messages.join("\n")
              exit(1)
            end
            if !dryrun
              sub_route.save!
            end
          end
          new_attributes = clone_in_current_generation(route_sub_route).attributes
          new_route_sub_route = new_gen_route.route_sub_routes.build(new_attributes)
          new_route_sub_route.sub_route = sub_route
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
      PaperTrail.enabled = true
    end
  end

end