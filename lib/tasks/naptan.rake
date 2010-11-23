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
    
    desc "Loads stop area type data from a CSV file specified as FILE=filename"
    task :stop_area_types => :environment do 
      parse('stop_area_types', Parsers::NaptanParser)
    end
  
    desc "Loads all data from CSV files in a directory specified as DIR=dirname"
    task :all => :environment do 
      unless ENV['DIR']
        usage_message "usage: rake naptan:load:all DIR=dirname"
      end
      puts "Loading data from #{ENV['DIR']}..."
      ENV['FILE'] = File.join(RAILS_ROOT, 'data', 'NaPTAN', 'StopTypes.csv')
      Rake::Task['naptan:load:stop_types'].execute
      ENV['FILE'] = File.join(RAILS_ROOT, 'data', 'NaPTAN', 'StopAreaTypes.csv')
      Rake::Task['naptan:load:stop_area_types'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'Stops.csv')
      Rake::Task['naptan:load:stops'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'StopAreas.csv')
      Rake::Task['naptan:load:stop_areas'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'StopsInArea.csv')
      Rake::Task['naptan:load:stop_area_memberships'].execute   
      ENV['FILE'] = File.join(ENV['DIR'], 'AreaHierarchy.csv')
      Rake::Task['naptan:load:stop_area_hierarchy'].execute   
    end
    
    desc 'Load new stop data from CSV file specified as FILE=filename'
    task :new_stops => :environment do 
      check_for_file
      puts "Loading new stops from #{ENV['FILE']}..."
      parser = Parsers::NaptanParser.new 
      stop_attributes = [:atco_code,
                         :naptan_code,
  		                   :plate_code,
                         :common_name,
                         :landmark,
                         :street,
                         :indicator,
                         :bearing,
                         :locality,
                         :town,
                         :suburb,
                         :locality_centre,
                         :easting,
                         :northing,
                         :lon,
                         :lat,
                         :stop_type,
                         :bus_stop_type, 
  		                   :modification_datetime, 
  		                   :status,
  		                   :notes]
      parser.send("parse_stops".to_sym, ENV['FILE']) do |new_stop|         
        existing_stop = Stop.find_by_atco_code(new_stop.atco_code)
        if existing_stop
          changed_attributes = []
          stop_attributes.each do |stop_attribute|
            new_value = new_stop.send(stop_attribute)
            old_value = existing_stop.send(stop_attribute)
            continue if (new_value.blank? && old_value.blank?) 
            continue if (new_value && old_value && new_value.to_s.downcase == old_value.to_s.downcase)
            if new_value != old_value
              changed_attributes << stop_attribute
            end
          end
          if !changed_attributes.empty? 
            puts "Found #{existing_stop.common_name} for #{new_stop.common_name}"
            changed_attributes.each do |attribute|
              puts "#{attribute}: old: #{existing_stop.send(attribute)}, new: #{new_stop.send(attribute)}"
            end
          end
        else
          puts "New stop #{new_stop.common_name}"
        end
          
      end
    end
  end
  
  namespace :post_load do 
    desc "Deletes stop areas with no stops"
    task :delete_unpopulated_stop_areas => :environment do 
      count = 0
      StopArea.find_each(:conditions => ['stop_area_memberships.id is null'],
                         :include => 'stop_area_memberships') do |stop_area|
        count += 1
        if stop_area.children.size > 0
          links = stop_area.links_as_ancestor + stop_area.links_as_descendant
          links.each do |link|
            if link.destroyable?
              link.destroy
            else
              link.make_indirect
              link.save!
            end
          end
        end
        StopArea.destroy(stop_area.id)
      end
      puts "Deleted #{count} unpopulated stop areas"
    end
    
    def find_stop_area_locality(stop_area)
      found = false
      localities = stop_area.stops.map{ |stop| stop.locality }.uniq
      if localities.size == 1
        # only one locality, choose that
        return localities.first
      else
        parent_localities = []
        localities.each do |locality|
          parent_localities += locality.parents
        end
        # none of the localities has a parent - just pick one
        if parent_localities.empty? 
          return localities.first
        end
        
        parent_localities.each do |parent_locality|
          # there's a parent that's either identical to or a parent of all the localities with parents
          if localities.all?{|locality| locality == parent_locality || locality.parents.empty? || locality.parents.include?(parent_locality) }
            # choose parent
            return parent_locality
          end
        end
      end
      # just pick the first
      return localities.first
    end
    
    desc 'Add locality_id to stop areas'
    task :add_locality_to_stop_areas => :environment do 
      StopArea.find_each do |stop_area|
        stop_area.locality = find_stop_area_locality(stop_area)
        stop_area.save
      end
    end
    
    desc 'Add TIPLOC and CRS codes to stops'
    task :add_stops_codes => :environment do 
      parse('rail_references', Parsers::NaptanParser)
    end
    
    desc 'Mark tram/metro stops - the BCT type is for bus, coach and metro and so metro searches always get swamped by bus stops'
    task :mark_metro_stops => :environment do
      # make sure default of false is set
      sql = Stop.send(:sanitize_sql_array, ["UPDATE stops SET metro_stop = ?", false]) 
      Stop.connection.execute(sql)
      # set metro type stops
      sql = Stop.send(:sanitize_sql_array, ["UPDATE stops SET metro_stop = ? WHERE stop_type in ('TMU', 'MET', 'PLT')", true]) 
      Stop.connection.execute(sql)
      # set stops on metro routes
      TramMetroRoute.find_each do |route|
        route.stops.each do |stop|
          stop.update_attribute(:metro_stop, true)
        end
      end
    end
  end
  
  namespace :geo do 
    
    desc "Adds 'coords' geometry values to Stops" 
    task :add_stops_coords => :environment do 
      spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
      adapter = ActiveRecord::Base.configurations[RAILS_ENV]['adapter']
      if ! spatial_extensions or ! adapter == 'postgresql'
        usage_message 'rake naptan:geo:add_stops_coords requires PostgreSQL with PostGIS'
      end
      Stop.find_each do |stop|
        coords = Point.from_x_y(stop.easting, stop.northing, BRITISH_NATIONAL_GRID)
        stop.coords = coords
        stop.save!
      end  
    end
    
    def convert_coords(class_name, task_name)
      spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
      adapter = ActiveRecord::Base.configurations[RAILS_ENV]['adapter']
      if ! spatial_extensions or ! adapter == 'postgresql'
        usage_message "rake naptan:geo:#{task_name} requires PostgreSQL with PostGIS"
      end
      class_name.constantize.find_each do |instance|
        conn = ActiveRecord::Base.connection
        lon_lats = conn.execute("SELECT st_X(st_transform(coords,#{WGS_84})) as lon, 
                                        st_Y(st_transform(coords,#{WGS_84})) as lat 
                                 FROM #{class_name.tableize} 
                                 WHERE id = #{instance.id}")
        lon_lat = lon_lats[0]
        if lon_lat.is_a? Hash
          instance.lon = lon_lat["lon"]
          instance.lat = lon_lat["lat"]
        else  
          instance.lon, instance.lat = lon_lat
        end
        instance.save!
      end
    end
    
    desc "Converts stop area coords from OS OSGB36 6-digit eastings and northings to WGS-84 lat/lons and saves the result on the model"
    task :convert_stop_areas => :environment do 
      convert_coords("StopArea", "convert_stop_areas")
    end
    
    desc "Converts locality coords from OS OSGB36 6-digit eastings and northings to WGS-84 lat/lons and saves the result on the model"
    task :convert_localities => :environment do 
      convert_coords("Locality", "convert_localities")
    end
  end
  
end