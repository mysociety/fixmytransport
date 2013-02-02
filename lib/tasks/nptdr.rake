require File.dirname(__FILE__) +  '/data_loader'

namespace :nptdr do

  include DataLoader
  include FixMyTransport::GeoFunctions

  def get_route_missing_stop_data()
    missing_route_stops_files = ["#{RAILS_ROOT}/data/NPTDR/oct_2010/missing_stops.csv",
                                 "#{RAILS_ROOT}/data/NPTDR/oct_2010/missing_stops_regional.csv"]
    route_stops = {}
    missing_route_stops_files.each do |missing_route_stops_file|
      FasterCSV.parse( File.read(missing_route_stops_file), csv_options) do |row|
        if route_stops[row['ATCO Code']]
          route_stops[row['ATCO Code']][:regions] << row['NPTDR File Region']
          route_stops[row['ATCO Code']][:admin_areas] << row['NPTDR File Admin Area']
          route_stops[row['ATCO Code']][:route_numbers] += row['NPTDR Route Numbers'].split(',')
        else
          route_stops[row['ATCO Code']] = { :regions => [row['NPTDR File Region']],
                                            :admin_areas => [row['NPTDR File Admin Area']],
                                            :route_numbers => row['NPTDR Route Numbers'].split(',') }
        end
      end
    end
    return route_stops
  end

  def csv_options
    { :quote_char => '"',
      :col_sep => "\t",
      :row_sep =>:auto,
      :return_headers => false,
      :headers => :first_row,
      :encoding => 'U' }
  end

  namespace :pre_load do

    desc 'Check stops data from any *.tsv files in directory specified DIR=dirname against existing stop data'
    task :check_stops => :environment do
      check_for_dir
      puts "Checking stops in #{ENV['DIR']}..."
      parser = Parsers::NptdrParser.new
      files = Dir.glob(File.join(ENV['DIR'], "*.tsv"))
      missing_file = File.open(File.join(ENV['DIR'], 'unmapped_stops.tsv'), 'w')
      missing_file.write("ATCO code\tName\tEasting\tNorthing\tLocality ID\n")
      unmatched_codes = {}
      unmatched_count = 0
      files.each do |file|
        puts file
        parser.parse_stops(file) do |stop|
          existing = Stop.find_by_atco_code(stop.atco_code)
          if ! existing && !unmatched_codes[stop.atco_code]
            unmatched_codes[stop.atco_code] = stop
          end
        end
      end
      unmatched_codes.each do |atco_code, stop|
        locality_id = (stop.locality ? stop.locality.id : nil)
        missing_file.write("#{stop.atco_code}\t#{stop.common_name}\t#{stop.easting}\t#{stop.northing}\t#{locality_id}\n")
      end
      puts "Unmatched: #{unmatched_codes.keys.size}"
    end

    def admin_area_name(admin_area)
      (admin_area == :national ? 'National' : admin_area.name)
    end

    def write_missing_stops(missing_stops, region, admin_area, stops_outfile)
      puts "Missing stops"
      missing_stops.each do |stop_code, route_list|
        values = [region.name,
                  admin_area_name(admin_area),
                  stop_code,
                  route_list.join(", ")]
        stops_outfile.write(values.join("\t") + "\n")
      end
      stops_outfile.flush
    end

    def write_missing_operators(unmatched_codes, ambiguous_codes, region, admin_area, operators_outfile)
      puts "Unmatched operator codes"
      unmatched_codes.each do |code, route_list|
        values = [region.name,
                  admin_area_name(admin_area),
                  code,
                  "missing",
                  route_list.join(", ")]
        operators_outfile.write(values.join("\t") + "\n")
      end
      puts "Ambiguous operator codes"
      ambiguous_codes.each do |code, route_list|
        values = [region.name,
                  admin_area_name(admin_area),
                  code,
                  "ambiguous",
                  route_list.join(", ")]
        operators_outfile.write(values.join("\t") + "\n")
      end
      operators_outfile.flush
    end

    desc 'Process routes from tsv files in a dir specified as DIR=dirname and output operator match and missing stop information'
    task :check_routes => :environment do
      check_for_dir
      puts "Checking routes in #{ENV['DIR']}..."
      parser = Parsers::NptdrParser.new
      dir = ENV['DIR']
      operators_outfile = File.open("#{RAILS_ROOT}/data/NPTDR/oct_2010/unmatched_operators.tsv", 'w')
      operators_headings = ["NPTDR File Region",
                            "NPTDR File Admin Area",
                            "NPTDR Operator Code",
                            "Code Problem",
                            "NPTDR Route Numbers"]
      operators_outfile.write(operators_headings.join("\t") + "\n")

      stops_outfile = File.open("#{RAILS_ROOT}/data/NPTDR/oct_2010/missing_stops.tsv", 'w')
      stops_headings = ["NPTDR File Region",
                        "NPTDR File Admin Area",
                        "ATCO Code",
                        "NPTDR Route Numbers"]
      stops_outfile.write(stops_headings.join("\t") + "\n")

      files = Dir.glob(File.join(ENV['DIR'], '*.tsv'))
      files.each do |file|
        unmatched_codes = {}
        ambiguous_codes = {}
        missing_stops = parser.parse_routes(file) do |route|
          route_string = "#{route.type} #{route.number}"
          if route.route_operators.size == 0
            if ! unmatched_codes[route.operator_code]
              unmatched_codes[route.operator_code] = []
            end
            if ! unmatched_codes[route.operator_code].include?(route_string)
              unmatched_codes[route.operator_code] << route_string
            end
          elsif route.route_operators.size > 1
            if ! ambiguous_codes[route.operator_code]
              ambiguous_codes[route.operator_code] = []
            end
            if ! ambiguous_codes[route.operator_code].include?(route_string)
              ambiguous_codes[route.operator_code] << route_string
            end
          end
        end
        admin_area = parser.admin_area_from_filepath(file)
        region = parser.region_from_filepath(file)
        puts "File: #{file} Region:#{region.name} Admin area: #{admin_area_name(admin_area)}"
        write_missing_operators(unmatched_codes, ambiguous_codes, region, admin_area, operators_outfile)
        write_missing_stops(missing_stops, region, admin_area, stops_outfile)
      end
      operators_outfile.close
      stops_outfile.close
    end
  end

  namespace :load do

    desc 'Loads operators data from the tsv file specified as FILE=filename'
    task :operators => :environment do
      check_for_file
      puts "Loading operator names from #{ENV['FILE']}..."
      parser = Parsers::NptdrParser.new
      parser.parse_operators(ENV['FILE']) do |operator|
        operator.save!
      end
    end

    desc 'Loads route data from zipped TransXChange files named *.txc in subdirectories of a directory specified as DIR=dirname'
    task :routes_from_transxchange => :environment do
      check_for_dir
      puts "Loading routes from #{ENV['DIR']}..."
      transport_mode = ENV['MODE']
      load_run = ENV['LOAD_RUN']
      Dir.glob(File.join(ENV['DIR'], '*/')).each do |subdir|
        zips = Dir.glob(File.join(subdir, '*.zip'))
        zips.each do |zip|
          puts "Loading routes from #{zip.inspect}"
          command = "rake RAILS_ENV=#{RAILS_ENV} nptdr:load:routes_from_transxchange_file FILE=\"#{zip}\" MODE=\"#{transport_mode}\" LOAD_RUN=\"#{load_run}\" --trace"
          exit_status = run_in_shell(command, file)
          raise "Process exited with error" unless exit_status == 0
        end
      end
    end

    desc 'Loads route data for one admin area from a zipped TransXChange file named *.txc in a directory specified as DIR=dirname'
    task :routes_from_transxchange_file => :environment do
      check_for_file
      transport_mode = ENV['MODE']
      load_run = ENV['LOAD_RUN']
      zip = ENV['FILE']
      Route.paper_trail_off
      RouteSegment.paper_trail_off
      RouteOperator.paper_trail_off
      JourneyPattern.paper_trail_off
      parser = Parsers::TransxchangeParser.new
      Zip::ZipFile.foreach(zip) do |txc_file|
        puts txc_file
        parser.parse_routes(txc_file.get_input_stream(), transport_mode, load_run, txc_file.to_s) do |route|
          # don't save ambiguous operators
          if route.route_operators.size > 1
            route.route_operators.clear
          end
          route.class.add!(route, verbose=true)
        end
      end
      Route.paper_trail_on
      RouteSegment.paper_trail_on
      RouteOperator.paper_trail_on
      JourneyPattern.paper_trail_on
    end

    desc 'Loads route data from TSV files named *.tsv in a directory specified as DIR=dirname'
    task :routes => :environment do
      check_for_dir
      puts "Loading routes from #{ENV['DIR']}..."
      files = Dir.glob(File.join(ENV['DIR'], "*.tsv"))
      files.each do |file|
        puts "Loading routes from #{file}"
        command = "rake RAILS_ENV=#{ENV['RAILS_ENV']} nptdr:load:routes_from_file FILE=#{file}"
        run_in_shell(command, file)
      end
    end

    desc 'Loads route data from a TSV file specified as FILE=filename'
    task :routes_from_file => :environment do
      check_for_file
      file = ENV['FILE']
      puts "Loading routes from #{file}"
      parser = Parsers::NptdrParser.new
      parser.parse_routes(file) do |route|
        # don't save ambiguous operators
        if route.route_operators.size > 1
          route.route_operators.clear
        end
        route.class.add!(route, verbose=true)
      end
    end

    desc 'Deletes all route associated data'
    task :clear_routes => :environment do
      Route.connection.execute('DELETE FROM routes')
      RouteSegment.connection.execute('DELETE FROM route_segments')
      RouteOperator.connection.execute('DELETE FROM route_operators')
      RouteSourceAdminArea.connection.execute('DELETE FROM route_source_admin_areas')
      JourneyPattern.connection.execute('DELETE FROM journey_patterns')
      Route.connection.execute("DELETE FROM slugs where sluggable_type = 'Route'")
      LoadRunCompletion.connection.execute('DELETE FROM load_run_completions')
    end

    desc 'Loads stops referenced by routes in NPTDR, but not present in the database'
    task :missing_stops => :environment do
      all_missing_stops_file = "#{RAILS_ROOT}/data/NPTDR/oct_2010/unmapped_stops.csv"
      missing_route_stops_file = "#{RAILS_ROOT}/data/NPTDR/oct_2010/missing_stops.csv"

      all_stops = {}
      FasterCSV.parse(File.read(all_missing_stops_file), csv_options) do |row|
        all_stops[row['ATCO code']] = { :name => row['Name'],
                                        :easting => row['Easting'],
                                        :northing => row['Northing'],
                                        :locality => row['Locality ID'] }
      end

      route_stops = get_route_missing_stop_data()
      all_stops.each do |code, stop_info|
        coords = Point.from_x_y(stop_info[:easting], stop_info[:northing], BRITISH_NATIONAL_GRID)
        locality = Locality.find_by_code((stop_info[:locality_id]))
        if locality.blank?
          nearest_stop = Stop.find_nearest(stop_info[:easting], stop_info[:northing])
          locality = nearest_stop.locality
        end
        if route_stops[code] and stop_info[:easting] != '-1.0' and !stop_info[:name].blank? and stop_info[:name].strip != '-'
          route_numbers = route_stops[code][:route_numbers]
          route_types = route_numbers.map{ |route_number| route_number.split(' ').first }.uniq
          stop_type = nil
          if route_types.size == 1
            if route_types.first == 'BusRoute' or route_types.first == 'CoachRoute'
              stop_type = 'BCT'
            elsif route_types.first == 'FerryRoute'
              stop_type = 'FER'
            else
              raise "Unhandled route type #{route_types.first} for #{code}"
            end
          else
            raise "More than one route type #{route_types.inspect} for #{code}"
          end
          puts "Loading #{code} #{stop_info[:name]} #{locality.name}"
          stop = Stop.create!(:other_code => code,
                              :common_name => stop_info[:name],
                              :easting => stop_info[:easting],
                              :northing => stop_info[:northing],
                              :coords => coords,
                              :status => 'ACT',
                              :locality => locality,
                              :stop_type => stop_type)
        end
      end
      # Add lats and lons
      Rake::Task['naptan:geo:convert_stops'].execute
    end

  end

  namespace :post_load do

    desc 'Deletes routes without stops'
    task :delete_routes_without_stops => :environment do
      Route.find_each(:conditions => ['route_segments.id is null'],
                         :include => 'route_segments') do |route|
        Route.destroy(route.id)
      end
    end

    def get_routes_file(admin_area_name, region_name)
      if admin_area_name == 'National'
        filename = 'National.tsv'
      else
        region = Region.find(:first, :conditions => ['name = ?', region_name])
        admin_areas = region.admin_areas.find(:all, :conditions => ['name = ?', admin_area_name])
        raise "More than one admin_area called #{admin_area_name} in #{region_name}" if admin_areas.size > 1
        raise "No admin area #{admin_area_name} found in #{region_name}" if admin_areas.size < 1
        admin_area = admin_areas.first
        # get the directory where the nptdr-derived files are
        filename = "Admin_Area_#{admin_area.atco_code}.tsv"
      end
      routes_file = File.join(MySociety::Config.get('NPTDR_DERIVED_DIR', ''), 'routes', filename)
    end

    desc 'Load manually created stops from a TSV file specified as FILE'
    task :load_manual_stops => :environment do
      check_for_file

      # get a hash of missing stops and the routes that reference them
      route_stops = get_route_missing_stop_data()

      nptdr_parser = Parsers::NptdrParser.new
      FasterCSV.parse(File.read(ENV['FILE']), csv_options) do |row|
        stop = Stop.new( :common_name => row['Name'] ? row['Name'].strip : nil,
                         :easting => row['Easting'] ? row['Easting'].strip : nil,
                         :northing => row['Northing'] ? row['Northing'].strip : nil,
                         :lat => row['Lat'] ? row['Lat'].strip : nil,
                         :lon => row['Lon'] ? row['Lon'].strip : nil,
                         :status => 'ACT',
                         :other_code => row['ATCO code'] ? row['ATCO code'].strip : nil,
                         :stop_type => row['Stop type'] ? row['Stop type'].strip : nil)

        # check if already exists
        existing = Stop.find_by_code(stop.other_code)
        if existing
          puts "Stop already in db #{existing.inspect}"
          next
        end

        # add a locality
        locality_code = row['Locality ID'] ? row['Locality ID'].strip : nil
        if !locality_code.blank?
         stop.locality = Locality.find_by_code(locality_code)
        end

        # generate the coords
        if stop.easting.blank? or stop.northing.blank?
          if stop.lon.blank? or stop.lat.blank?
            raise "No coordinates for manual stop #{stop.atco_code}"
          else
            stop.easting, stop.northing = get_easting_northing(stop.lon, stop.lat)
          end
        end
        stop.coords = Point.from_x_y(stop.easting, stop.northing, BRITISH_NATIONAL_GRID)

        # look for a station if this is part of a station
        station_part_stops = StopType.station_part_types
        station_types = StopType.station_part_types_to_station_types
        if station_part_stops.include?(stop.stop_type)
          station_type = station_types[stop.stop_type]
          puts "Looking for a parent of type #{station_type} for #{stop.common_name}" if ENV['DRYRUN']
          existing_stations = StopArea.find_parents(stop, station_type)
          if existing_stations.empty?
            puts "Couldn't find parent for #{stop.common_name} (#{stop.other_code})" if ENV['DRYRUN']
          elsif existing_stations.size > 1
            puts "More than one possible parent for #{stop.common_name} (#{stop.other_code}), please add manually" if ENV['DRYRUN']
          else
            puts "Adding #{existing_stations.first.name} as parent of #{stop.common_name}" if ENV['DRYRUN']
            stop.stop_area_memberships.build(:stop_area => existing_stations.first)
          end
        end

        if ! ENV['DRYRUN']
           # save the stop
          stop.save!

          # convert easting/northing to lat/lon
          if stop.lon.blank? or stop.lat.blank?
            stop = set_lon_lat(stop, 'Stop')
            stop.save!
          end

          # approximate a locality if needed
          if !stop.locality
            nearest_stop = Stop.find_nearest(stop.easting, stop.northing, exclude_id=stop.id)
            stop.locality = nearest_stop.locality
            stop.save!
          end

          # are there any routes missing this stop?
          if route_stops[stop.other_code]
            route_data = route_stops[stop.other_code]
            puts "Inserting #{stop.common_name} into routes"
            matched_journeys = {}
            tried_codes = []
            route_data[:admin_areas].zip(route_data[:regions]).each do |admin_area_name, region_name|
              routes_file = get_routes_file(admin_area_name, region_name)
              route_numbers = route_data[:route_numbers].map{ |route_desc| route_desc.split(" ")[1] }
              nptdr_parser.parse_routes(routes_file, only_numbers=route_numbers) do |route|
                new_matches, tried_codes = get_journey_patterns_to_replace(route, admin_area_name, stop, nptdr_parser, tried_codes)
                matched_journeys.update(new_matches)
              end
            end
            matched_journeys.each do |journey_pattern_id, replacement_pattern|
              journey_pattern = JourneyPattern.find(journey_pattern_id)
              route = journey_pattern.route
              journey_pattern.destroy
              replacement_pattern.route = route
              replacement_pattern.route_segments.each{ |segment| segment.route = route }
              replacement_pattern.save!
              replacement_pattern.route.cache_route_coords
              replacement_pattern.route.cache_route_description
              replacement_pattern.route.save!
            end
          end
        end
      end
    end

    def get_journey_patterns_to_replace(route, admin_area_name, stop, nptdr_parser, tried_codes)
      matched_journeys = {}
      if admin_area_name == 'National'
        options = {:any_admin_area => true}
      else
        options = {}
      end
      existing_routes = Route.find_all_by_number_and_common_stop(route, options)
      route.journey_patterns.each do |journey_pattern|
        stops = journey_pattern.stop_list()
        # for any journey pattern including the new stop
        if stops.include?(stop)
          stops.delete(stop)
          stop_codes = stops.map{ |stop| stop.atco_code or stop.other_code }
          next if tried_codes.include?(stop_codes)
          tried_codes << stop_codes
          comparison_journey = JourneyPattern.new
          # make a comparison pattern without it
          nptdr_parser.build_segments_for_journey_pattern(comparison_journey, route, stop_codes, {})
          # and find existing journey patterns in the db that match it.
          existing_routes.each do |existing_route|
            match = false
            existing_route.journey_patterns.each do |existing_journey_pattern|
              if match == false && existing_journey_pattern.identical_segments?(comparison_journey)
                matched_journeys[existing_journey_pattern.id] = journey_pattern
                match = true
                next
              end
            end
          end
        end
      end
      [ matched_journeys, tried_codes ]
    end

    desc 'Merges consecutively loaded pairs of bus routes from the same operator going between the same places'
    task :merge_consecutive_bus_route_pairs => :environment do
      count = 0
      bus_mode = TransportMode.find_by_name("Bus")
      Route.find_each(:conditions => ['transport_mode_id = ?', bus_mode]) do |route|
        next_route = Route.find(:first,
                                :conditions => ['transport_mode_id = ? and id > ?', 1, route.id],
                                :order => 'id asc')
        next unless next_route && next_route.number == route.number && next_route.operator_code == route.operator_code
        route.source_admin_areas.each do |source_admin_area|
          next unless next_route.source_admin_areas.detect{ |next_source_admin_area| next_source_admin_area.id == source_admin_area.id }
        end
        route_words = route.description.split.sort
        next_route_words = next_route.description.split.sort
        if route_words != next_route_words
          next
        end
        puts "Merging #{route.description} #{route.id} #{next_route.description} #{next_route.id}"
        Route.merge_duplicate_route(next_route, route)
        count += 1
      end
      puts count
    end

    desc 'Merges routes by operator code and description'
    task :merge_identical_routes_by_operator_and_description => :environment do
      results = Route.connection.execute("SELECT cached_description, operator_code, cnt
                                          FROM (SELECT cached_description, operator_code, count(*) as cnt
                                                FROM routes
                                                GROUP BY cached_description, operator_code ) as tmp
                                          WHERE cnt > 1;")
      results.each do |result|
        cached_description = result['cached_description']
        operator_code = result['operator_code']
        routes = Route.find(:all, :conditions => ['cached_description = ? and operator_code = ?',
                                                   cached_description, operator_code])
        next if routes.empty?
        options = { :any_admin_area => true,
                    :require_total_match => true,
                    :use_operator_codes => true }
        found = Route.find_all_by_number_and_common_stop(routes.first, options)
        next if found.empty?
        puts "Merging #{found.map{|route| route.id }.join(" ")} to #{routes.first.id} for #{cached_description} #{operator_code}"
        Route.merge!(routes.first, found)
      end
    end

    desc 'Merges national routes into routes from admin areas'
    task :merge_national_routes => :environment do
      route_type = ENV['ROUTE_TYPE']
      total = route_type.constantize.maximum(:id)
      great_britain = Region.find_by_name('Great Britain')
      offset = ENV['OFFSET'] ? ENV['OFFSET'].to_i : route_type.constantize.minimum(:id, :conditions => ['region_id = ?', great_britain])
      puts "Merging routes ..."
      while offset < total
        puts "Merging routes from offset #{offset}"
        command = "rake RAILS_ENV=#{RAILS_ENV} nptdr:post_load:merge_national_route_set OFFSET=#{offset} ROUTE_TYPE=#{route_type}"
        run_in_shell(command, offset)
        offset += 100
      end
    end

    desc 'Merges a set of national routes into routes from admin areas'
    task :merge_national_route_set => :environment do
      great_britain = Region.find_by_name('Great Britain')
      offset = ENV['OFFSET'] ? ENV['OFFSET'].to_i : 1
      route_type = ENV['ROUTE_TYPE'].constantize
      max = offset + 100
      route_type.find_each(:conditions => ['id >= ?
                                       AND id <= ?
                                       AND region_id = ?
                                       AND id NOT IN (
                                         SELECT route_id
                                         FROM route_operators)', offset, max, great_britain]) do |route|
        existing_routes = Route.find_all_by_number_and_common_stop(route, {:any_admin_area => true})
        if existing_routes.size == 1
          existing_route = existing_routes.first
          puts "merging #{existing_route.cached_description} #{route.cached_description}"
          Route.merge_duplicate_route(route, existing_route)
        end
        puts route.id
      end
    end

    desc 'Generate list of merge candidates from national routes'
    task :generate_merge_candidates_national => :environment do
      great_britain = Region.find_by_name('Great Britain')
      routes = BusRoute.find(:all, :conditions => ['region_id = ?
                                                     AND id NOT IN (
                                                      SELECT route_id
                                                      FROM route_operators)', great_britain])
      routes.each do |route|
        others = Route.find_all_by_number_and_common_stop(route, options={:skip_operator_comparison => true})
        if ! others.empty?
          MergeCandidate.create!(:national_route => route, :regional_route_ids => others.map{|route| route.id}.join("|"))
        end
      end
    end

    desc 'Generate list of merge candidates from bus routes that have the same number, region and cached description'
    task :generate_merge_candidates_by_number => :environment do
      routes = BusRoute.find_by_sql("SELECT a.* from routes as a, routes as b
                                     WHERE a.id > b.id
                                     AND a.number = b.number
                                     AND a.transport_mode_id = 1
                                     AND b.transport_mode_id = 1
                                     AND a.cached_description = b.cached_description")
       routes.each do |route|
         others = Route.find_all_by_number_and_common_stop(route, options={:skip_operator_comparison => true})
         if ! others.empty?
           MergeCandidate.create!(:national_route => route, :regional_route_ids => others.map{|route| route.id}.join("|"))
         end
       end
    end

    desc 'Merge candidates marked in the route comparison interface as being the same'
    task :merge_marked_candidates => :environment do
      MergeCandidate.find_each(:conditions => ['is_same = ?', true]) do |merge_candidate|
        other_route_ids = merge_candidate.regional_route_ids.split("|")
        route_ids = [merge_candidate.national_route_id] + other_route_ids
        routes = route_ids.map{ |route_id| Route.find(:first, :conditions => ['id = ?', route_id]) }.compact
        if routes.size > 1
          to_merge = routes.shift
          puts "merging #{to_merge.id} #{to_merge.cached_description} to #{routes.map{|route| "#{route.id} #{route.cached_description}"}}"
          Route.merge!(to_merge, routes)
        end
        merge_candidate.destroy
      end
    end


    desc 'Adds region associations based on route localities'
    task :add_route_regions => :environment do
      total = Route.maximum(:id)
      offset = ENV['OFFSET'] ? ENV['OFFSET'].to_i : Route.minimum(:id)
      puts "Adding locations for routes ..."
      while offset < total
        puts "Adding locations from offset #{offset}"
        command = "rake RAILS_ENV=#{RAILS_ENV} nptdr:post_load:add_region_to_route_set OFFSET=#{offset}"
        run_in_shell(command, offset)
        offset += 100
      end
    end

    desc 'Adds region associations to a set of routes based on route localities'
    task :add_region_to_route_set => :environment do
      offset = ENV['OFFSET'] ? ENV['OFFSET'].to_i : 1
      max = offset + 100
      great_britain = Region.find_by_name('Great Britain')
      Route.find_each(:conditions => ['id >= ? AND id <= ?', offset, max]) do |route|
        regions = route.localities.map{ |locality| locality.admin_area.region }.uniq
        if regions.size > 1
          regions = [great_britain]
        end
        if regions.size == 0
          puts "Couldn't assign region to #{route.inspect}"
        end
        route.region = regions.first
        route.save!
      end
    end

    desc 'Adds cached route locality associations based on route stop localities'
    task :add_route_localities => :environment do
      total = Route.maximum(:id)
      offset = ENV['OFFSET'] ? ENV['OFFSET'].to_i : RouteLocality.minimum(:route_id)
      offset = Route.minimum(:id) if offset.nil?
      puts "Adding locations for routes ..."
      while offset < total
        puts "Adding locations from offset #{offset}"
        command = "rake RAILS_ENV=#{RAILS_ENV} nptdr:post_load:add_route_locality_sets OFFSET=#{offset}"
        run_in_shell(command, offset)
        offset += 100
      end

    end

    desc 'Adds cached route locality associations to a set of routes based on route stop localities'
    task :add_route_locality_sets => :environment do
      offset = ENV['OFFSET'] ? ENV['OFFSET'].to_i : 1
      max = offset + 100
      Route.paper_trail_off
      Route.find_each(:conditions => ['id >= ? AND id <= ?', offset, max]) do |route|
        puts route.id
        locality_ids = []
        route.stops.each do |stop|
          locality_ids << stop.locality_id unless locality_ids.include? stop.locality_id
        end
        locality_ids.each do |locality_id|
          if ! route.route_localities.detect{ |existing| existing.locality_id == locality_id }
            route.route_localities.build(:locality_id => locality_id)
          end
        end
        route.save!
      end
      Route.paper_trail_on
    end

    desc 'Adds lats and lons to routes calculated from stops'
    task :add_route_coords => :environment do
      Route.paper_trail_off
      Route.find_each(:conditions => ["lat is null"]) do |route|
        puts route.name
        if ! route.lat
          lons = route.stops.map{ |element| element.lon }
          lats = route.stops.map{ |element| element.lat }
          lon = lons.min + ((lons.max - lons.min)/2)
          lat = lats.min + ((lats.max - lats.min)/2)
          route.lat = lat
          route.lon = lon
          route.save!
        end
      end
      Route.paper_trail_on
    end

    desc 'Cache route descriptions'
    task :cache_route_descriptions => :environment do
      Route.paper_trail_off
      Route.find_each(:conditions => ["cached_description is null"]) do |route|
        route.cached_description = route.description
        route.save!
      end
      Route.paper_trail_on
    end

    desc 'Adds stop_area_ids to route_segments for train, ferry and metro station interchange and platform stops'
    task :add_stop_areas_to_route_segments => :environment do
      conditions = ["stop_type in (?)", StopType.station_part_types]
      station_types = StopType.station_part_types_to_station_types
      interchange_stops = Stop.find_each(:conditions => conditions) do |interchange_stop|
        station_stop_area = interchange_stop.root_stop_area(station_types[interchange_stop.stop_type])
        if !station_stop_area
          puts  "No station for #{interchange_stop.name}"
          next
        end
        # puts "Adding #{station_stop_area.name} to segments for #{interchange_stop.name}"
        interchange_stop.route_segments_as_from_stop.each do |route_segment|
          route_segment.from_stop_area_id = station_stop_area.id
          route_segment.save!
        end
        interchange_stop.route_segments_as_to_stop.each do |route_segment|
          route_segment.to_stop_area_id = station_stop_area.id
          route_segment.save!
        end
      end
    end

    desc 'Generate list of 100 routes for data audit'
    task :generate_audit_set => :environment do
      include ActionController::UrlWriter
      # Can be checked for duplicate routes, incorrectly merged routes, bad operator assignments
      audit_file = File.open("#{RAILS_ROOT}/data/audit.tsv", 'w')
      headers = ["Route ID", "Description", "URL", "Operators", "Does the description map to more than one (identical looking) route?", "Do the route terminuses look about right compared to any external source you can find?", "Is the operator right (if there is one)?"]
      audit_file.write(headers.join("\t") + "\n")
      random_routes = Route.find(:all, :order => 'random()', :limit => 100)
      random_routes.each do |route|
        route_url = route_url(route.region, route, :host => MySociety::Config.get("DOMAIN", "localhost:3000"))
        route_operators = route.operators.map{|operator| operator.name}.to_sentence
        fields = [route.id,
                  route.description,
                  route_url,
                  route_operators]
        audit_file.write(fields.join("\t") + "\n")
      end
    end

    desc 'Show stats on data completion'
    task :status => :environment do

      # routes without operators
      puts "Routes without operators: #{Route.count_without_operators} out of #{Route.count}"

      # operators without contact details
      puts "Missing operators contacts #{Operator.count_without_contacts} out of #{Operator.count}, affects #{Route.count_without_contacts} out of #{Route.count} routes"

    end

  end

end