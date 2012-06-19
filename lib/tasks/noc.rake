require 'fixmytransport/data_loader'
# Rake tasks for handling the National Operator Codes spreadsheet
namespace :noc do

  include FixMyTransport::DataLoader

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

    desc "Loads stop area operator information from a TSV file specified as FILE=filename.
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

    desc "Updates stop area operators (which are not included in NOC) from a TSV file specified as
          FILE=filename. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag
          set by VERBOSE=1"
    task :station_operators => :environment do
      load_instances_in_generation(StopAreaOperator, Parsers::OperatorsParser)
    end

    desc "Create stop operators (which are not included in NOC) in the current generation.
          Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1'"
    task :stop_operators => :environment do
      dryrun = check_dryrun
      verbose = check_verbose
      PaperTrail.enabled = false
      # At the moment, the only stop operator records are for the Isle of Wight bus stops
      # run by Southern Vectis
      southern_vectis = Operator.current.find_by_name('Southern Vectis')
      isle_of_wight = AdminArea.current.find_by_name('Isle of Wight')
      isle_of_wight.localities.each do |locality|
        locality.stops.each do |stop|
          puts "Creating stop operator for #{stop.common_name} #{southern_vectis.name}"
          stop_operator = stop.stop_operators.build(:operator => southern_vectis)
          existing = StopOperator.find_in_generation_by_identity_hash(stop_operator, PREVIOUS_GENERATION)
          if existing
            stop_operator.previous_id = existing.id
            stop_operator.persistent_id = existing.persistent_id
          end
          if !stop_operator.valid?
            puts "ERROR: Stop operator is invalid:"
            puts stop_operator.inspect
            puts stop_operator.errors.full_messages.join("\n")
            exit(1)
          end
          if !dryrun
            stop_operator.save!
          end
        end
      end
      PaperTrail.enabled = true
    end

  end

end