require File.dirname(__FILE__) +  '/data_loader'
namespace :nptg do
  
  include DataLoader
  
  namespace :match do 
  
    desc 'Matches stops to localities using the nptg_locality_code field' 
    task :stops_to_localities => :environment do 
      Stop.find_each do |stop|
        locality = Locality.find_by_code(stop.nptg_locality_code)
        stop.locality = locality
        stop.save!
      end
    end
    
  end
  
  namespace :load do
    
    desc "Loads regions from a CSV file specified as FILE=filename"
    task :regions => :environment do 
      parse('regions', Parsers::NptgParser)
    end
  
    desc "Loads admin area data from a CSV file specified as FILE=filename"
    task :admin_areas => :environment do 
      parse('admin_areas', Parsers::NptgParser)
    end     

    desc "Loads district from a CSV file specified as FILE=filename"
    task :districts => :environment do 
      parse('districts', Parsers::NptgParser)
    end
    
    desc "Loads locality data from a CSV file specified as FILE=filename"
    task :localities => :environment do 
      parse('localities', Parsers::NptgParser)
    end
    
    desc "Loads locality hierarchy data from a CSV file specified as FILE=filename"
    task :locality_hierarchy => :environment do 
      parse('locality_hierarchy', Parsers::NptgParser)
    end
    
    desc "Loads locality alternative name data from a CSV file specified as FILE=filename"
    task :locality_alternative_names => :environment do 
      parse('locality_alternative_names', Parsers::NptgParser)
    end
        
    desc "Loads all data from CSV files in a directory specified as DIR=dirname"
    task :all => :environment do 
      unless ENV['DIR']
        usage_message "usage: rake nptg:load:all DIR=dirname"
      end
      puts "Loading data from #{ENV['DIR']}..."
      ENV['FILE'] = File.join(ENV['DIR'], 'Travel Regions.csv')
      Rake::Task['nptg:load:regions'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'Admin Areas.csv')
      Rake::Task['nptg:load:admin_areas'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'Districts.csv')
      Rake::Task['nptg:load:districts'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'Localities.csv')
      Rake::Task['nptg:load:localities'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'Hierarchy.csv')
      Rake::Task['nptg:load:locality_hierarchy'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'AlternativeNames.csv')
      Rake::Task['nptg:load:locality_alternative_names'].execute
    end
    
  end
  

  
end