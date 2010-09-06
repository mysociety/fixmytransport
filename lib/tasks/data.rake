require File.dirname(__FILE__) +  '/data_loader'
require "#{RAILS_ROOT}/app/helpers/application_helper"
namespace :data do 
  
  include DataLoader
  
  desc "Create a spreadsheet of organizations that don't have contact information"
  task :create_organization_contact_spreadsheet => :environment do 
    
    include ActionController::UrlWriter
    include ApplicationHelper
    ActionController.default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')
    
    check_for_dir
    puts "Writing PTE contact spreadsheet to #{ENV['DIR']}..."
    File.open(File.join(ENV['DIR'], 'ptes.tsv'), 'w') do |pte_file|
      pte_file.write("Passenger Transport Executive\tWikipedia URL\tContact email\tNotes\n")
      PassengerTransportExecutive.find_each do |pte|
        pte_file.write([pte.name, pte.wikipedia_url, pte.email].join("\t") + "\n")
      end
    end
    
    puts "Writing operator contact spreadsheet to #{ENV['DIR']}..."
    File.open(File.join(ENV['DIR'], 'operators.tsv'), 'w') do |operator_file|
      operator_file.write("ID\tOperator\tShort name\tContact email\tNotes\tRoute count\troutes\n")
      
      Operator.find(:all, :order => 'name').each do |operator|
        if operator.routes.count > 0
          routes = operator.routes.map{ |route| location_url(route) }.join(" ")
          operator_file.write([operator.id, 
                               operator.name, 
                               operator.short_name, 
                               operator.email,
                               operator.notes,
                               operator.routes.count, 
                               routes].join("\t") + "\n")
        end
      end
    end
    
  end
end