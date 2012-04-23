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

    desc "Loads operators from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :operators => :environment do
      parse(Operator, Parsers::NocParser)
    end

    desc "Loads operator codes in different regions from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :operator_codes => :environment do
      parse(OperatorCode, Parsers::NocParser)
    end

    desc "Loads vosa licenses from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :vosa_licenses => :environment do
      parse(VosaLicense, Parsers::NocParser)
    end

    desc "Loads operator contact information from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :operator_contacts => :environment do
      parse(OperatorContact, Parsers::OperatorContactsParser)
    end

    desc "Loads stop area operator information from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :station_operators => :environment do
      parse(StopAreaOperator, Parsers::OperatorsParser)
    end

    desc 'Loads operator contact information from a Traveline format of CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified.'
    task :traveline_operator_contacts => :environment do
      parse(OperatorContact, Parsers::OperatorContactsParser, 'parse_traveline_operator_contacts')
    end

  end

  namespace :update do

    desc "Updates operators from a TSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :operators => :environment do
       load_instances_in_generation(Operator, Parsers::NocParser)
    end

    desc "Updates operator codes from a TSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :operator_codes => :environment do
      load_instances_in_generation(OperatorCode, Parsers::NocParser)
    end

    desc "Updates vosa licenses from a TSV file specified as FILE=filename to generation id specified
          as GENERATION=generation. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :vosa_licenses => :environment do
      load_instances_in_generation(VosaLicense, Parsers::NocParser)
    end

    desc "Updates operator contacts to the current generation.
          Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1.
          Depends on noc:update:operators having been run."
    task :operator_contacts => :environment do
      verbose = check_verbose
      dryrun = check_dryrun
      # find operator contacts in previous generation
      operator_contacts = nil
      # for each one, find the successor operator and the successor location
      OperatorContact.in_generation(PREVIOUS_GENERATION) do
        operator_contacts = OperatorContact.find(:all)
      end
      operator_contacts.each do |operator_contact|
        operator_id = operator_contact.operator_id
        if operator_contact.location_type && operator_contact.location_id
          location_class = operator_contact.location_type
          location_id = operator_contact.location_id
          new_location = location_class.constantize.find_successor(location_id)
          if new_location.nil?
            puts "Location in operator contact #{operator_contact.id} does not have successor: #{location_class}, #{location_id}"
          end
        end
        new_operator = Operator.find_successor(operator_id)
        if new_operator.nil?
          puts "Operator in operator contact #{operator_contact.id} does not have successor: #{operator_id}"
        end

        # References are the same, promote the model to the new data generation
        if (!location_id || new_location.id == location_id) && (new_operator.id == operator_id)
          if operator_contact.generation_high < CURRENT_GENERATION
            operator_contact.generation_high = CURRENT_GENERATION
            if ! operator_contact.valid?
              error_message = "Updated operator contact invalid #{operator_contact.id}:\n"
              error_message += operator_contact.errors.full_messages.join("\n")
              raise error_message
            end
            puts "Setting generation_high on operator_contact #{operator_contact.id}" if verbose
            if !dryrun
              operator_contact.save!
            end
          end
        # References not the same, add a new operator contact for this generation
        else
          if OperatorContact.find_successor(operator_contact.id)
            next
          end
          puts "Creating new operator_contact for #{operator_contact.id}" if verbose
          new_operator_contact = operator_contact.clone
          new_operator_contact.generation_low = CURRENT_GENERATION
          new_operator_contact.generation_high = CURRENT_GENERATION
          if location_id
            new_operator_contact.location_id = new_location.id
          end
          new_operator_contact.operator_id = new_operator.id
          new_operator_contact.previous_id = operator_contact.id
          if ! new_operator_contact.valid?
            error_message = "New operator contact for previous id #{operator_contact.id} invalid:\n"
            error_message += new_operator_contact.errors.full_messages.join("\n")
            raise error_message
          end
          if !dryrun
            new_operator_contact.save!
          end
        end
      end
    end
  end

end