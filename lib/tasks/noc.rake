# Rake tasks for handling the National Operator Codes spreadsheet
require File.dirname(__FILE__) +  '/data_loader'
namespace :noc do
  
  include DataLoader
  
  namespace :load do
    
    desc "Loads operators from a CSV file specified as FILE=filename"
    task :operators => :environment do 
      parse('operators', Parsers::NocParser)
    end

  end
  
end