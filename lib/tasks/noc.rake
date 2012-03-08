# Rake tasks for handling the National Operator Codes spreadsheet
require File.dirname(__FILE__) +  '/data_loader'
namespace :noc do

  include DataLoader

  namespace :pre_load do

    desc "Parses operator contact information and produces output about what would be loaded. Requires a CSV file specified as FILE=filename"
    task :operator_contacts => :environment do
      parser = Parsers::OperatorContactsParser.new
      parser.parse_operator_contacts(ENV['FILE'], dryrun=true)
    end

    desc 'Parses operator contact information from a Traveline format file and produces output about what would be loaded. Requires a CSV file specified as FILE=filename'
    task :traveline_operator_contacts => :environment do
      parser = Parsers::OperatorContactsParser.new
      parser.parse_traveline_operator_contacts(ENV['FILE'], dryrun=true)
    end
  end

  namespace :load do

    desc "Loads operators from a CSV file specified as FILE=filename"
    task :operators => :environment do
      parse('operators', Parsers::NocParser)
    end

    desc "Loads operator codes in different regions from a CSV file specified as FILE=filename"
    task :operator_codes => :environment do
      parse('operator_codes', Parsers::NocParser)
    end

    desc "Loads vosa licenses from a CSV file specified as FILE=filename"
    task :vosa_licenses => :environment do
      parse('vosa_licenses', Parsers::NocParser)
    end

    desc "Loads operator contact information from a CSV file specified as FILE=filename"
    task :operator_contacts => :environment do
      parse('operator_contacts', Parsers::OperatorContactsParser)
    end

    desc "Loads stop area operator information from a CSV file specified as FILE=filename"
    task :station_operators => :environment do
      parse('station_operators', Parsers::OperatorsParser)
    end

    desc 'Loads operator contact information from a Traveline format of CSV file specified as FILE=filename'
    task :traveline_operator_contacts => :environment do
      parse('traveline_operator_contacts', Parsers::OperatorContactsParser)
    end

  end

  namespace :update do

    desc "Updates operators from a TSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :operators => :environment do

       field_hash = { :identity_fields => [:noc_code],
                      :new_record_fields => [:name, :transport_mode_id],
                      :update_fields => [:vosa_license_name,
                                         :parent,
                                         :ultimate_parent,
                                         :vehicle_mode] }
       load_instances_in_generation(Operator, Parsers::NocParser, field_hash)
    end

    desc "Updates operator codes from a TSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :operator_codes => :environment do

      field_hash = { :identity_fields => [:region_id, :operator_id, :code],
                     :new_record_fields => [],
                     :update_fields => [] }
      load_instances_in_generation(OperatorCode, Parsers::NocParser, field_hash)
    end

    desc "Updates vosa licenses from a TSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :vosa_licenses => :environment do

      field_hash = { :identity_fields => [:operator_id, :number],
                     :new_record_fields => [],
                     :update_fields => [] }
      load_instances_in_generation(VosaLicense, Parsers::NocParser, field_hash)
    end

  end

end