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
    
    desc "Converts stop area coords from OS OSGB36 6-digit eastings and northings to WGS-84 lat/lons and saves the result on the model"
    task :convert_stop_areas => :environment do 
      spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
      adapter = ActiveRecord::Base.configurations[RAILS_ENV]['adapter']
      if ! spatial_extensions or ! adapter == 'postgresql'
        usage_message 'rake naptan:geo:convert_stop_areas requires PostgreSQL with PostGIS'
      end
      StopArea.find_each do |stop_area|
        conn = ActiveRecord::Base.connection
        lon_lats = conn.execute("SELECT st_X(st_transform(coords,#{WGS_84})) as lon, 
                                        st_Y(st_transform(coords,#{WGS_84})) as lat 
                                 FROM stop_areas 
                                 WHERE id = #{stop_area.id}")
        lon_lat = lon_lats[0]
        if lon_lat.is_a? Hash
          stop_area.lon = lon_lat["lon"]
          stop_area.lat = lon_lat["lat"]
        else  
          stop_area.lon, stop_area.lat = lon_lat
        end
        stop_area.save!
      end
    end
  end
  
  namespace :temp do 
    task :merge_tram_and_metro => :environment do 
      
      StopAreaType.connection.execute("DELETE FROM transport_mode_stop_area_types")      
      StopAreaType.connection.execute("DELETE FROM stop_area_types")
      StopType.connection.execute("DELETE FROM stop_types")
      #delete tram from transport mode
      TransportMode.connection.execute("DELETE FROM transport_modes
                                        WHERE name = 'Tram'")
      #update naptan name in transport_mode 
      TransportMode.connection.execute("UPDATE transport_modes 
                                        SET name = 'Tram/Metro', naptan_name = 'Tram / Metro', route_type = 'TramMetroRoute'
                                        WHERE name = 'Metro'")
      

      ENV['FILE'] = File.join(RAILS_ROOT, 'data', 'NaPTAN', 'StopTypes.csv')
      Rake::Task['naptan:load:stop_types'].execute
      ENV['FILE'] = File.join(RAILS_ROOT, 'data', 'NaPTAN', 'StopAreaTypes.csv')
      Rake::Task['naptan:load:stop_area_types'].execute
      Route.connection.execute("UPDATE routes 
                                SET type = 'TramMetroRoute'
                                WHERE type = 'MetroRoute'")
    end
    
    task :delete_bad_stop_area_memberships => :environment do
      Stop.find(4).stop_area_memberships.each do |stop_area_membership|
        StopAreaMembership.delete(stop_area_membership.id)
      end
      StopArea.find(4).stop_area_memberships.each do |stop_area_membership|
        if stop_area_membership.stop_id != 6192
          StopAreaMembership.delete(stop_area_membership.id)
        end
      end
    end
  end
  
end