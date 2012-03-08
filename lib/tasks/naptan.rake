require File.dirname(__FILE__) +  '/data_loader'
require File.dirname(__FILE__) +  '/../fixmytransport/geo_functions'

namespace :naptan do

  namespace :load do

    include DataLoader
    include FixMyTransport::GeoFunctions

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
      ENV['FILE'] = File.join(ENV['DIR'], 'Groups.csv')
      Rake::Task['naptan:load:stop_areas'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'StopsInGroup.csv')
      Rake::Task['naptan:load:stop_area_memberships'].execute
      ENV['FILE'] = File.join(ENV['DIR'], 'GroupsInGroup.csv')
      Rake::Task['naptan:load:stop_area_hierarchy'].execute
    end
  end

  namespace :post_load do
  
    desc "Deletes stop areas with no stops"
    task :delete_unpopulated_stop_areas => :environment do
      count = 0
      StopArea.find_each(:conditions => ['stop_area_memberships.id is null'],
                         :include => 'stop_area_memberships') do |stop_area|
        puts stop_area.name
        puts stop_area.area_type
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
      if stop_area.stops.empty?
        nearest_stop = Stop.find_nearest(stop_area.easting, stop_area.northing)
        return nearest_stop.locality
      else
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
            if localities.all?{ |locality| locality == parent_locality || locality.parents.empty? || locality.parents.include?(parent_locality) }
              # choose parent
              return parent_locality
            end
          end
        end
        # just pick the first
        return localities.first
      end
    end

    desc 'Add locality_id to stop areas'
    task :add_locality_to_stop_areas => :environment do
      StopArea.connection.execute("DELETE
                                   FROM slugs
                                   WHERE sluggable_type = 'StopArea'
                                   AND scope is null;")
      StopArea.paper_trail_off
      StopArea.find_each(:conditions => ['locality_id is NULL']) do |stop_area|
        puts stop_area.name
        locality = find_stop_area_locality(stop_area)
        stop_area.locality = find_stop_area_locality(stop_area)
        stop_area.save!
      end
      StopArea.paper_trail_on
    end

    desc 'Add locality_id to any stop missing it'
    task :add_locality_to_stops => :environment do
      Stop.find_each(:conditions => ['locality_id is NULL']) do |stop|
        nearest_stop = Stop.find_nearest(stop.easting, stop.northing, exclude_id=stop.id)
        stop.locality = nearest_stop.locality
        stop.save!
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

    desc 'Add double metaphone values to stations'
    task :add_station_metaphones => :environment do
      station_types = StopAreaType.atomic_types
      StopArea.paper_trail_off
      StopArea.find_each(:conditions => ["area_type in (?)", station_types]) do |station|
        normalized_name = station.name.gsub(' & ', ' and ')
        primary_metaphone, secondary_metaphone = Text::Metaphone.double_metaphone(normalized_name)
        puts "#{station.name} #{primary_metaphone} #{secondary_metaphone}"
        station.primary_metaphone = primary_metaphone
        station.secondary_metaphone = secondary_metaphone
        station.save!
      end
      StopArea.paper_trail_on
    end


    desc 'Add double metaphone values to localities'
    task :add_locality_metaphones => :environment do
      Locality.find_each do |locality|
        normalized_name = locality.name.gsub(' & ', ' and ')
        primary_metaphone, secondary_metaphone = Text::Metaphone.double_metaphone(normalized_name)
        puts "#{locality.name} #{primary_metaphone} #{secondary_metaphone}"
        locality.primary_metaphone = primary_metaphone
        locality.secondary_metaphone = secondary_metaphone
        locality.save!
      end
    end

  end

  namespace :update do

    desc 'Updates stops from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1'
    task :stops => :environment do
      field_hash = { :identity_fields => [:atco_code],
                     :new_record_fields => [:common_name, :naptan_code, :plate_code,
                                            :landmark, :street, :crossing, :indicator,
                                            :bearing, :locality_id, :easting, :northing,
                                            :lon, :lat, :stop_type, :bus_stop_type,
                                            :easting, :northing, :status],
                     :update_fields => [:short_common_name,
                                        :town, :suburb, :locality_centre, :grid_type,
                                        :administrative_area_code, :creation_datetime,
                                        :modification_datetime, :modification, :revision_number],
                     :deletion_field => :modification,
                     :deletion_value => 'del' }
      load_instances_in_generation(Stop, Parsers::NaptanParser, field_hash)
    end

    desc 'Updates stop areas from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1'
    task :stop_areas => :environment do
      field_hash = { :identity_fields => [:code],
                     :new_record_fields => [:name, :area_type, :easting, :northing, :lon, :lat, :status],
                     :update_fields => [:grid_type, :administrative_area_code, :creation_datetime,
                                        :modification_datetime, :modification, :revision_number],
                     :deletion_field => :modification,
                     :deletion_value => 'del' }
      load_instances_in_generation(StopArea, Parsers::NaptanParser, field_hash) do |stop_area|
        stop_area.status = 'ACT' if stop_area.status.nil?
      end
    end

    desc 'Updates stop area memberships from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1'
    task :stop_area_memberships => :environment do
      field_hash = { :identity_fields => [:stop_id, :stop_area_id],
                     :new_record_fields => [],
                     :update_fields => [:creation_datetime, :modification_datetime,
                                        :modification, :revision_number],
                     :deletion_field => :modification,
                     :deletion_value => 'del' }
      load_instances_in_generation(StopAreaMembership, Parsers::NaptanParser, field_hash)
    end

  end

  namespace :geo do

    desc "Adds 'coords' geometry values to Stops"
    task :add_stops_coords => :environment do
      Stop.find_each do |stop|
        coords = Point.from_x_y(stop.easting, stop.northing, BRITISH_NATIONAL_GRID)
        stop.coords = coords
        stop.save!
      end
    end

    desc "Adds lat/lons for any stops without them by converting from OS OSGB36 6-digit eastings and northings"
    task :convert_stops => :environment do
      convert_coords("Stop", "convert_stops", 'lat is null')
    end

    desc "Converts stop area coords from OS OSGB36 6-digit eastings and northings to WGS-84 lat/lons and saves the result on the model"
    task :convert_stop_areas => :environment do
      convert_coords("StopArea", "convert_stop_areas", 'lat is null')
    end

  end

end