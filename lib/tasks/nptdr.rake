require File.dirname(__FILE__) +  '/data_loader'
namespace :nptdr do
    
  include DataLoader

  namespace :pre_load do 
  
    desc 'Check stops data from any *.tsv files in directory specified DIR=dirname against existing stop data'
    task :check_stops => :environment do 
      check_for_dir
      puts "Checking stops in #{ENV['DIR']}..."
      parser = Parsers::NptdrParser.new
      files = Dir.glob(File.join(ENV['DIR'], "*.tsv"))
      outfile = File.open(File.join(ENV['DIR'], "stop_mappings.tsv"), 'w')
      puts "Writing old to new mappings to #{outfile}"
      outfile.write("Old ATCO code\tNew ATCO code\tOld name\tOld Easting\tOld Northing\n")
      unmatched_count = 0
      files.each do |file|
        puts file
        parser.parse_stops(file) do |stop|
          existing = Stop.match_old_stop(stop)
          if ! existing
            unmatched_count += 1
          end
          if existing and existing.atco_code != stop.atco_code
            outfile.write "#{stop.atco_code}\t#{existing.atco_code}\t#{stop.common_name}\t#{stop.easting}\t#{stop.northing}\n"
          end
        end        
      end
      puts "Unmatched: #{unmatched_count}"
    end 
    
    desc 'Process routes from tsv files in a dir specified as DIR=dirname and output operator match and missing stop information'
    task :check_routes => :environment do 
      check_for_dir
      puts "Checking routes in #{ENV['DIR']}..."
      parser = Parsers::NptdrParser.new
      dir = ENV['DIR']
      operators_outfile = File.open("#{RAILS_ROOT}/data/nptdr/unmatched_operators.tsv", 'w')
      operators_headings = ["NPTDR File Region", 
                            "NPTDR File Admin Area", 
                            "NPTDR Operator Code",
                            "Code Problem",
                            "NPTDR Route Numbers"]
      operators_outfile.write(operators_headings.join("\t") + "\n")
      
      stops_outfile = File.open("#{RAILS_ROOT}/data/nptdr/missing_stops.tsv", 'w')
      stops_headings = ["NPTDR File Region", 
                        "NPTDR File Admin Area", 
                        "ATCO Code", 
                        "NPTDR Route Numbers"]
      stops_outfile.write(stops_headings.join("\t") + "\n")                  
      
      files = Dir.glob(File.join(ENV['DIR'], "Admin_Area*.tsv"))
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
        
        puts "File: #{file} Region:#{admin_area.region.name} Admin area: #{admin_area.name}"
        puts "Unmatched operator codes"
        unmatched_codes.each do |code, route_list|
          values = [admin_area.region.name, 
                    admin_area.name, 
                    code, 
                    "missing",
                    route_list.join(", ")]
          operators_outfile.write(values.join("\t") + "\n")
        end
        puts "Ambiguous operator codes"        
        ambiguous_codes.each do |code, route_list|
          values = [admin_area.region.name, 
                    admin_area.name, 
                    code, 
                    "ambiguous in region",
                    route_list.join(", ")]
          operators_outfile.write(values.join("\t") + "\n")
        end
        puts "Missing stops"
        missing_stops.each do |stop_code, route_list|
          values = [admin_area.region.name, 
                    admin_area.name, 
                    stop_code, 
                    route_list.join(", ")]
          stops_outfile.write(values.join("\t") + "\n")
        end
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
    
    desc 'Loads route data from TSV files named *.tsv in a directory specified as DIR=dirname'
    task :routes => :environment do 
      check_for_dir
      puts "Loading routes from #{ENV['DIR']}..."
      parser = Parsers::NptdrParser.new 
      files = Dir.glob(File.join(ENV['DIR'], "*.tsv"))
      files.each do |file|
        puts "Loading routes from #{file}"
        parser.parse_routes(file) do |route| 
          route.class.add!(route, verbose=true)
        end
      end
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
    
    desc 'Deletes operators whose code has no routes'
    task :delete_operator_codes_without_routes => :environment do 
      deleted_count = 0
      Operator.find_each do |operator|
        if Route.count_by_sql(["SELECT count(*) from routes where operator_code = ?", operator.code]) == 0
         puts "deleting #{operator.name} #{operator.code}"
         deleted_count += 1
        end
      end
      puts "Deleted #{deleted_count} operators"
    end
    
    desc 'Assigns routes to operators if the operator code of the route is unique'
    task :add_route_operators => :environment do 
      # Match up any codes where we only have one operator. Not foolproof as we know that
      # our set of operators is incomplete
      Route.find_each do |route|
        operators = Operator.find_all_by_code(route.operator_code)
        if operators.size == 1 
          route.route_operators.create(:operator => operators.first)
        end
      end
    end
    
    desc 'Adds region associations based on route localities'
    task :add_route_regions => :environment do 
      great_britain = Region.find_by_name('Great Britain')
      Route.find_each do |route|
        regions = route.localities.map{ |locality| locality.admin_area.region }.uniq
        if regions.size > 1 
          regions = [great_britain]
        end
        if regions.size == 0
          raise route.inspect
        end
        route.region = regions.first
        route.save!
      end
    end
    
    desc 'Adds cached route locality associations based on route stop localities' 
    task :add_route_localities => :environment do 
      Route.find_each do |route|
        localities = []
        route.stops.each do |stop|
          localities << stop.locality unless localities.include? stop.locality
        end
        localities.each do |locality|
          route.route_localities.build(:locality => locality)
        end
        route.save!
      end
    end
    
    desc 'Adds lats and lons to routes calculated from stops'
    task :add_route_coords => :environment do 
      Route.paper_trail_off
      Route.find_each(:conditions => ['lat is null']) do |route|
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
  end
  
end