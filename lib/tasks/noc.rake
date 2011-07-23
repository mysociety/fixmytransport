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


end