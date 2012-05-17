require 'fixmytransport/data_loader'
# Rake tasks for handling council data
namespace :councils do

  include FixMyTransport::DataLoader

  namespace :load do

    desc "Loads council contacts from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :contacts => :environment do
      parse(CouncilContact, Parsers::FmsContactsParser)
    end

  end

end