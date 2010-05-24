require File.dirname(__FILE__) +  '/data_loader'
namespace :nptdr do
    
  include DataLoader

  namespace :preload do 
  
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
          route.class.add!(route)
        end
      end
    end
    
  end
  
  namespace :postload do 
    
    desc "Removes redundant segments from routes"
    task :routes => :environment do 
      unless ENV['ROUTE_ID']
        usage_message "usage: This task requires ROUTE_ID=route_id"
      end
      route_id = ENV['ROUTE_ID']
      route = Route.find(route_id)
      route.route_segments.each do |route_segment|
        
      end
    end
  end

end