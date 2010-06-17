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
      outfile.write("Old ATCO code\tNew ATCO code\n")
      unmatched_count = 0
      files.each do |file|
        puts file
        parser.parse_stops(file) do |stop|
          existing = Stop.match_old_stop(stop)
          if ! existing
            unmatched_count += 1
          end
          if existing and existing.atco_code != stop.atco_code
            outfile.write "#{stop.atco_code}\t#{existing.atco_code}\n"
          end
        end        
      end
      puts "Unmatched: #{unmatched_count}"
    end 

  end
  
  namespace :load do
       
    desc "Loads operator data from a TSV file specified as FILE=filename"
    task :operators => :environment do 
      check_for_file 
      puts "Loading operators from #{ENV['FILE']}..."
      parser = Parsers::NptdrParser.new 
      parser.parse_operators(ENV['FILE']) do |operator| 
        existing = Operator.find(:all, :conditions => ["lower(code) = ? and lower(name) = ? and lower(short_name) = ?",
                                       operator.code.downcase, operator.name.downcase, operator.short_name.downcase])
        next if !existing.empty?
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
    
    desc 'Adds region associations based on route localities'
    task :add_route_regions => :environment do 
      great_britain = Region.find_by_name('Great Britain')
      Route.find_each do |route|
        regions = route.localities.map{|locality| locality.admin_area.region }.uniq
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
  end
end