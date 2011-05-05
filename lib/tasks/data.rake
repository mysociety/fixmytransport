require File.dirname(__FILE__) +  '/data_loader'
require "#{RAILS_ROOT}/app/helpers/application_helper"
namespace :data do 
  
  include DataLoader
  
  desc "Create a spreadsheet of organizations' contact information"
  task :create_organization_contact_spreadsheet => :environment do 
    
    include ActionController::UrlWriter
    ActionController.default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')
    
    check_for_dir
    puts "Writing PTE contact spreadsheet to #{ENV['DIR']}..."
    File.open(File.join(ENV['DIR'], 'ptes.tsv'), 'w') do |pte_file|
      pte_file.write("Passenger Transport Executive\tWikipedia URL\tContact email\tNotes\n")
      PassengerTransportExecutive.find_each do |pte|
        pte_file.write([pte.name, pte.wikipedia_url, pte.email].join("\t") + "\n")
      end
    end
    
    puts "Writing council contact spreadsheet to #{ENV['DIR']}..."
    File.open(File.join(ENV['DIR'], 'council_contacts.tsv'), 'w') do |council_contacts_file|
      council_contacts_file.write("Council\tArea ID\tContact category\tContact district ID\tContact email\tNotes\n")
      Council.find_all_without_ptes().each do |council|
        council.contacts.each do |council_contact|
          council_contacts_file.write([council.name, 
                                       council.id, 
                                       council_contact.category, 
                                       council_contact.district_id, 
                                       council_contact.email, 
                                       council_contact.notes].join("\t") + "\n")
        end
      end  
    end
    
    puts "Writing operator contact spreadsheet to #{ENV['DIR']}..."
    File.open(File.join(ENV['DIR'], 'operator_contacts.tsv'), 'w') do |operator_contact_file|
      operator_contact_file.write("ID\tOperator\tCompany no\tRegistered address\tCompany URL\tContact category\tContact location\tContact email\tNotes\tRoute count\tURL - has list of routes\n")
      
      Operator.find(:all, :order => 'name').each do |operator|
        if operator.routes.count > 0
          operator.operator_contacts.each do |operator_contact|
            if operator_contact.location
              location_desc = operator_contact.location.description
            else
              location_desc = ''
            end
            operator_contact_file.write([operator.id, 
                                         operator.name, 
                                         operator.company_no, 
                                         operator.registered_address,
                                         operator.url,
                                         operator_contact.category, 
                                         location_desc,
                                         operator_contact.email,
                                         operator_contact.notes,
                                         operator.routes.count, 
                                         operator_url(operator)].join("\t") + "\n")
          end
        end
      end
    end
    
  end
end