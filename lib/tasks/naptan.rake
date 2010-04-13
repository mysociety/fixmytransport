namespace :naptan do
    
  namespace :load do
    
    def check_for_file taskname
      unless ENV['FILE']
        puts ''
        puts "usage: rake naptan:load:#{taskname} FILE=filename"
        puts ''
        exit 0
      end
    end
    
    def parse(model)
      check_for_file model
      puts "Loading #{model} from #{ENV['FILE']}..."
      parser = Parsers::NaptanParser.new 
      parser.send("parse_#{model}".to_sym, ENV['FILE']){ |model| model.save! }
    end
  
    desc "Loads stop data from a CSV file specified as FILE=filename"
    task :stops => :environment do 
      parse('stops')
    end 
    
    desc "Loads stop area data from a CSV file specified as FILE=filename"
    task :stop_areas => :environment do 
      parse('stop_areas')
    end
    
    desc "Loads stop area membership data from a CSV file specified as FILE=filename"
    task :stop_area_memberships => :environment do 
      parse('stop_area_memberships')
    end
    
    desc "Loads stop type data from a CSV file specified as FILE=filename"
    task :stop_types => :environment do 
      parse('stop_types')
    end
    
    desc "Loads all data from CSV files in a directory specified as DIR=dirname"
    task :all => :environment do 
      unless ENV['DIR']
        puts ''
        puts "usage: rake naptan:load:all DIR=dirname"
        puts ''
        exit 0
      end
      puts "Loading data from #{ENV['DIR']}..."
      ENV['FILE'] = File.join(ENV['DIR'], 'StopTypes.csv')
      Rake::Task['naptan:load:stop_types'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'Stops.csv')
      Rake::Task['naptan:load:stops'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'StopAreas.csv')
      Rake::Task['naptan:load:stop_areas'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'StopsInArea.csv')
      Rake::Task['naptan:load:stop_area_memberships'].execute      
    end
  
  end
  
end