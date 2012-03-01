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

    desc "Updates districts with the admin areas given in the locality data"
    task :add_district_admin_areas => :environment do
      District.find_each(:conditions => ['admin_area_id is null']) do |district|
        admin_areas = district.localities.map{ |locality| locality.admin_area }.uniq
        puts "#{district.name} has #{district.localities.size} localities"
        raise "More than one admin area for district #{district.name} #{admin_areas.inspect}" unless admin_areas.size <= 1
        district.admin_area = admin_areas.first
        district.save!
      end
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
      Rake::Task['nptg:load:add_district_admin_areas'].execute
    end

  end

  namespace :post_load do

    desc 'Split the name and qualifier for localities, which in the 2010 data release are in one field with the qualifier in brackets'
    task :split_locality_qualifiers => :environment do
      Locality.find_each(:conditions => ["name like ?", '%%(%%']) do |locality|
        name_pattern = /\s*(.*)\s+\((.*)\)\s*/
        match_data = name_pattern.match(locality.name)
        name = match_data[1]
        qualifier = match_data[2]
        puts "name: #{name}, qualifier: #{qualifier}"
        locality.name = name
        locality.qualifier_name = qualifier
        locality.save!
      end
    end

  end
  
  namespace :update do

    desc "Updates regions from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :regions => :environment do
      verbose = check_verbose()
      dryrun = check_dryrun()
      previous_generation = get_previous_generation()
      parse_for_update('regions', Parsers::NptgParser) do |region|
        region.generation_low = ENV['GENERATION']
        region.generation_high = ENV['GENERATION']
        search_conditions = { :code => region.code,
                              :name => region.name,
                              :creation_datetime => region.creation_datetime,
                              :modification_datetime => region.modification_datetime,
                              :modification => region.modification }
        existing_region = Region.find_in_generation(previous_generation, :first, :conditions => search_conditions)
        if existing_region
          puts "Setting generation_high to #{ENV['GENERATION']} on #{existing_region.name} #{existing_region.code}"
          if ! dryrun
            existing_region.update_attribute('generation_high', ENV['GENERATION'])
          end
        else
          existing_region = Region.find_in_generation(previous_generation, :first, :conditions => ['code = ?
                                                                                                    AND name = ?',
                                                                                                    region.code, region.name])
          if existing_region
            puts "Updating attributes for #{existing_region.name} #{existing_region.code}"
            puts existing_region.diff(region).inspect if verbose
            region.previous_id = existing_region.id
          else
            puts "New region #{region.name} #{region.code}"
          end
          if ! dryrun
            region.save
          end
        end
      end
    end

    desc "Updates admin areas from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :admin_areas => :environment do
      verbose = check_verbose()
      dryrun = check_dryrun()
      previous_generation = get_previous_generation()
      country_map = { 'Eng' => 'England',
                      'Sco' => 'Scotland',
                      'Gre' => 'Great Britain',
                      'Wal' => 'Wales' }
      parse_for_update('admin_areas', Parsers::NptgParser) do |admin_area|
        admin_area.generation_low = ENV['GENERATION']
        admin_area.generation_high = ENV['GENERATION']
        search_conditions = { :code => admin_area.code,
                              :atco_code => admin_area.atco_code,
                              :name => admin_area.name,
                              :country => country_map[admin_area.country],
                              :region_id => admin_area.region_id,
                              :creation_datetime => admin_area.creation_datetime,
                              :modification_datetime => admin_area.modification_datetime,
                              :modification => admin_area.modification,
                              :revision_number => admin_area.revision_number }
        existing_admin_area = AdminArea.find_in_generation(previous_generation,
                                                           :first,
                                                           :conditions => search_conditions)
        if existing_admin_area
          puts "Setting generation_high to #{ENV['GENERATION']} on #{existing_admin_area.name} #{existing_admin_area.code}"
          if ! dryrun
            existing_admin_area.update_attribute('generation_high', ENV['GENERATION'])
          end
        else
          existing_admin_area = AdminArea.find_in_generation(previous_generation,
                                                             :first,
                                                             :conditions => ['code = ?
                                                             AND name = ?
                                                             AND atco_code = ?',
                                                             admin_area.code,
                                                             admin_area.name,
                                                             admin_area.atco_code])
          if existing_admin_area
            puts "Updating attributes for #{existing_admin_area.name} #{existing_admin_area.code}"
            puts existing_admin_area.diff(admin_area).inspect if verbose
            admin_area.previous_id = existing_admin_area.id
          else
            puts "New admin area #{admin_area.name} #{admin_area.code}"
          end
          if ! dryrun
            admin_area.save
          end
        end
      end
    end

    desc "Updates districts from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :districts => :environment do
      verbose = check_verbose()
      dryrun = check_dryrun()
      previous_generation = get_previous_generation()
      parse_for_update('districts', Parsers::NptgParser) do |district|
        district.generation_low = ENV['GENERATION']
        district.generation_high = ENV['GENERATION']
        search_conditions = { :code => district.code,
                              :name => district.name,
                              :creation_datetime => district.creation_datetime,
                              :modification_datetime => district.modification_datetime,
                              :modification => district.modification,
                              :revision_number => district.revision_number }
        existing_district = District.find_in_generation(previous_generation,
                                                        :first,
                                                        :conditions => search_conditions)
        if existing_district
          puts "Setting generation_high to #{ENV['GENERATION']} on #{existing_district.name} #{existing_district.code}"
          if ! dryrun
            existing_district.update_attribute('generation_high', ENV['GENERATION'])
          end
        else
          existing_district = District.find_in_generation(previous_generation,
                                                          :first,
                                                          :conditions => ['code = ?
                                                             AND name = ?',
                                                             district.code,
                                                             district.name])
          if existing_district
            puts "Updating attributes for #{existing_district.name} #{existing_district.code}"
            puts existing_district.diff(district).inspect if verbose
            district.previous_id = existing_district.id
          else
            puts "New district #{district.name} #{district.code}"
          end
          if ! dryrun
            district.save
          end
        end
      end
    end

    desc "Updates localities from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :localities => :environment do
      verbose = check_verbose()
      dryrun = check_dryrun()
      previous_generation = get_previous_generation()
      parse_for_update('localities', Parsers::NptgParser) do |locality|
        locality.generation_low = ENV['GENERATION']
        locality.generation_high = ENV['GENERATION']
        search_conditions = { :code                      => locality.code,
                              :name                      => locality.name,
                              :short_name                => locality.short_name,
                              :qualifier_name            => locality.qualifier_name,
                              :admin_area_id             => locality.admin_area.id,
                              :district_id               => locality.district ? locality.district.id : nil,
                              :source_locality_type      => locality.source_locality_type,
                              :grid_type                 => locality.grid_type,
                              :easting                   => locality.easting,
                              :northing                  => locality.northing,
                              :coords                    => locality.coords,
                              :creation_datetime         => locality.creation_datetime,
                              :modification_datetime     => locality.modification_datetime,
                              :revision_number           => locality.revision_number,
                              :modification              => locality.modification }
        existing_locality = Locality.find_in_generation(previous_generation,
                                                        :first,
                                                        :conditions => search_conditions)
        if existing_locality
          puts "Setting generation_high to #{ENV['GENERATION']} on #{existing_locality.name} #{existing_locality.code}"
          if ! dryrun
            existing_locality.update_attribute('generation_high', ENV['GENERATION'])
          end
        else
          existing_locality = Locality.find_in_generation(previous_generation,
                                                          :first,
                                                          :conditions => ['code = ?
                                                             AND name = ?',
                                                             locality.code,
                                                             locality.name])
          if existing_locality
            # puts "Updating attributes for #{existing_locality.name} #{existing_locality.code}"
            puts existing_locality.diff(locality).inspect if verbose
            locality.previous_id = existing_locality.id
          else
            puts "New locality #{locality.name} #{locality.code}"
          end
          if ! dryrun
            locality.save
          end
        end
      end
    end
  end
  

end