# Rake tasks for handling council data
require File.dirname(__FILE__) +  '/data_loader'
namespace :councils do
  
  include DataLoader
  
  namespace :load do
    
    desc "Loads council contacts from a CSV file specified as FILE=filename.
          Runs in dryrun mode unless DRYRUN=0 is specified."
    task :contacts => :environment do 
      parse(CouncilContact, Parsers::FmsContactsParser)
    end
   
  end
  
end