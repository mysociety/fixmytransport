require 'fixmytransport/data_loader'
require 'fixmytransport/geo_functions'
namespace :naptan do

  namespace :load do

    include FixMyTransport::DataLoader
    include FixMyTransport::GeoFunctions

    desc "Loads stop data from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :stops => :environment do
      parse(Stop, Parsers::NaptanParser)
    end

    desc "Loads stop area data from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :stop_areas => :environment do
      parse(StopArea, Parsers::NaptanParser)
    end

    desc "Loads stop area membership data from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :stop_area_memberships => :environment do
      parse(StopAreaMembership, Parsers::NaptanParser)
    end

    desc "Loads stop area hierarchy from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :stop_area_hierarchy => :environment do
      parse(StopAreaLink, Parsers::NaptanParser)
    end

    desc "Loads stop type data from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :stop_types => :environment do
      parse(StopType, Parsers::NaptanParser)
    end

    desc "Loads stop area type data from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :stop_area_types => :environment do
      parse(StopAreaType, Parsers::NaptanParser)
    end

    desc "Loads all data from CSV files in a directory specified as DIR=dirname.
          Runs in dryrun mode unless DRYRUN=0 is specified."
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
      StopArea.current.find_each(:conditions => ['stop_area_memberships.id is null'],
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
        nearest_stop = Stop.find_nearest_current(stop_area.easting, stop_area.northing)
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
      PaperTrail.enabled = false
      StopArea.current.find_each(:conditions => ['locality_id is NULL']) do |stop_area|
        puts stop_area.name
        locality = find_stop_area_locality(stop_area)
        stop_area.locality = find_stop_area_locality(stop_area)
        stop_area.save!
      end
      PaperTrail.enabled = true
    end

    desc 'Add locality_id to any stop missing it'
    task :add_locality_to_stops => :environment do
      PaperTrail.enabled = false
      extra_conditions = "locality_id is not null"
      Stop.current.find_each(:conditions => ['locality_id is NULL']) do |stop|
        nearest_stop = Stop.find_nearest_current(stop.easting, stop.northing, exclude_id=stop.id, extra_conditions)
        puts stop.inspect
        stop.locality = nearest_stop.locality
        stop.save!
      end
      PaperTrail.enabled = true
    end

    desc 'Add TIPLOC and CRS codes to stops'
    task :add_stops_codes => :environment do
      parse(Stop, Parsers::NaptanParser, 'parse_rail_references')
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

  namespace :update do

    desc 'Updates stops from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1'
    task :stops => :environment do
      load_instances_in_generation(Stop, Parsers::NaptanParser)
    end

    desc 'Updates stop areas from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1'
    task :stop_areas => :environment do
      load_instances_in_generation(StopArea, Parsers::NaptanParser) do |stop_area|
        stop_area.status = 'ACT' if stop_area.status.nil?
      end
    end

    desc 'Updates stop area memberships from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1'
    task :stop_area_memberships => :environment do
      load_instances_in_generation(StopAreaMembership, Parsers::NaptanParser)
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