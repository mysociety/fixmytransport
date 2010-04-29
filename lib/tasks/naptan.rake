require File.dirname(__FILE__) +  '/data_loader'
namespace :naptan do
    
  namespace :load do
    
    include DataLoader
  
    desc "Loads stop data from a CSV file specified as FILE=filename"
    task :stops => :environment do 
      parse('stops', Parsers::NaptanParser)
    end 
    
    desc "Loads stop area data from a CSV file specified as FILE=filename"
    task :stop_areas => :environment do 
      parse('stop_areas', Parsers::NaptanParser)
    end
    
    desc "Loads stop area membership data from a CSV file specified as FILE=filename"
    task :stop_area_memberships => :environment do 
      parse('stop_area_memberships', Parsers::NaptanParser)
    end
    
    desc "Loads stop area hierarchy from a CSV file specified as FILE=filename"
    task :stop_area_hierarchy => :environment do 
      parse('stop_area_hierarchy', Parsers::NaptanParser)
    end
    
    
    desc "Loads stop type data from a CSV file specified as FILE=filename"
    task :stop_types => :environment do 
      parse('stop_types', Parsers::NaptanParser)
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
      ENV['FILE'] = File.join(ENV['DIR'], 'AreaHierarchy.csv')
      Rake::Task['naptan:load:stop_area_hierarchy'].execute   
    end
    
  end
  
  namespace :convert do 
    desc "Converts stop area coords from OS OSGB36 6-digit eastings and northings to WGS-84 lat/lons and saves the result on the model"
    task :os_to_lat_lon => :environment do 
      spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
      adapter = ActiveRecord::Base.configurations[RAILS_ENV]['adapter']
      if ! spatial_extensions or ! adapter == 'postgresql'
        puts ''
        puts 'rake naptan:convert:os_to_lat_lon requires PostgreSQL with PostGIS'
        puts ''
        exit 0
      end
      StopArea.find_each do |stop_area|
        conn = ActiveRecord::Base.connection
        lon_lats = conn.execute("SELECT st_X(st_transform(coords,#{WGS_84})) as lon, 
                                        st_Y(st_transform(coords,#{WGS_84})) as lat 
                                 FROM stop_areas 
                                 WHERE id = #{stop_area.id}")
        lon_lat = lon_lats[0]
        if lon_lat.is_a? Hash
          stop_area.lon = lon_lat[:lon]
          stop_area.lat = lon_lat[:lat]
        else  
          stop_area.lon, stop_area.lat = lon_lat
        end
        stop_area.save!
      end
    end
  end
  
end