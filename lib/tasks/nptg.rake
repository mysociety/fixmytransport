require 'fixmytransport/data_loader'
namespace :nptg do

  include FixMyTransport::DataLoader

  namespace :load do

    desc "Loads regions from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :regions => :environment do
      parse('regions', Parsers::NptgParser)
    end

    desc "Loads admin area data from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :admin_areas => :environment do
      parse('admin_areas', Parsers::NptgParser)
    end

    desc "Loads district from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :districts => :environment do
      parse('districts', Parsers::NptgParser)
    end

    desc "Loads locality data from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :localities => :environment do
      parse('localities', Parsers::NptgParser)
    end

    desc "Loads locality hierarchy data from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :locality_links => :environment do
      parse('locality_links', Parsers::NptgParser)
    end

    desc "Updates districts with the admin areas given in the locality data"
    task :add_district_admin_areas => :environment do
      District.current.find_each(:conditions => ['admin_area_id is null']) do |district|
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
      Rake::Task['nptg:load:locality_links'].execute
      Rake::Task['nptg:load:add_district_admin_areas'].execute
    end

  end
  namespace :geo do
    desc "Converts locality coords from OS OSGB36 6-digit eastings and northings to WGS-84 lat/lons and saves the result on the model"
    task :convert_localities => :environment do
      convert_coords("Locality", "convert_localities", 'lat is null')
    end
  end

  namespace :post_load do

    desc 'Split the name and qualifier for localities, which in the 2010 data release are in one field with the qualifier in brackets'
    task :split_locality_qualifiers => :environment do
      Locality.current.find_each(:conditions => ["name like ?", '%%(%%']) do |locality|
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
      load_instances_in_generation(Region, Parsers::NptgParser)
    end

    desc "Updates admin areas from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :admin_areas => :environment do
      country_map = { 'Eng' => 'England',
                      'Sco' => 'Scotland',
                      'Gre' => 'Great Britain',
                      'Wal' => 'Wales' }
      load_instances_in_generation(AdminArea, Parsers::NptgParser) do |admin_area|
        admin_area.country = country_map[admin_area.country]
      end
    end

    desc "Updates districts from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :districts => :environment do
      load_instances_in_generation(District, Parsers::NptgParser)
    end

    desc "Updates localities from a CSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :localities => :environment do
      load_instances_in_generation(Locality, Parsers::NptgParser)
    end

  end
end