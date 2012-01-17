require File.dirname(__FILE__) +  '/data_loader'
require "#{RAILS_ROOT}/app/helpers/application_helper"
namespace :data do

  include DataLoader
  
  desc 'Create a spreadsheet of problems'
  task :create_problem_spreadsheet => :environment do 
   
    include ActionController::UrlWriter
    ActionController.default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')
    include ApplicationHelper
    
    check_for_dir
    puts "Writing problem spreadsheet to #{ENV['DIR']}..."
    File.open(File.join(ENV['DIR'], 'problems.tsv'), 'w') do |problem_file|
      headers = ['ID', 
                 'Subject', 
                 'Campaign', 
                 'Problem URL',
                 'Campaign URL',
                 'Location',
                 'Transport mode', 
                 'Reporter', 
                 'Organization', 
                 'Status', 
                 'Created', 
                 'Updated',
                 'Supporters',
                 'Comments']
      # add supporters, comments 
      problem_file.write(headers.join("\t") + "\n")
      Problem.find_each(:conditions => ['status_code in (?)', Problem.visible_status_codes]) do |problem|
        if problem.campaign
          problem_url = ''
          campaign = problem.campaign
          campaign_url = campaign_url(campaign)
          supporters = campaign.supporters.count
          comments = campaign.comments.visible.count
        else
          problem_url = problem_url(problem)
          campaign_url = ''
          supporters = ''
          comments = problem.comments.visible.count
        end
        columns = [problem.id, 
                   problem.subject, 
                   problem.campaign ? 'Y' : 'N',
                   problem_url,
                   campaign_url, 
                   problem.location.name,
                   problem.transport_mode_text,
                   problem.reporter.name,
                   problem.responsible_organizations.map{ |org| org.name }.to_sentence,
                   problem.status,
                   problem.created_at.localtime.to_s(:short), 
                   problem.updated_at.localtime.to_s(:short),
                   supporters,
                   comments]
        problem_file.write(columns.join("\t") + "\n")
      end
    end
  end
  
  
  desc "Create a spreadsheet of praise reports" 
  task :create_praise_spreadsheet => :environment do 
    
    include ActionController::UrlWriter
    ActionController.default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')
    include ApplicationHelper
    
    check_for_dir
    puts "Writing praise spreadsheet to #{ENV['DIR']}..."
    File.open(File.join(ENV['DIR'], 'praise.tsv'), 'w') do |praise_file|
      headers = ['URL', 'Date', 'Text', 'User']
      praise_file.write(headers.join("\t") + "\n")
      # Any comment attached to a location is praise
      locations = ['Stop', 'StopArea', 'Route', 'SubRoute']
      Comment.find_each(:conditions => ['commented_type in (?)', locations]) do |comment|
        praise_file.write([commented_url(comment.commented), 
                           comment.confirmed_at.to_s, 
                           "\"#{comment.text}\"",
                           comment.user_name].join("\t") + "\n")
      end
    end
  end

  desc "Create a spreadsheet of organizations' contact information"
  task :create_organization_contact_spreadsheet => :environment do

    include ActionController::UrlWriter
    ActionController.default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')

    check_for_dir
    puts "Writing PTE contact spreadsheet to #{ENV['DIR']}..."
    File.open(File.join(ENV['DIR'], 'ptes.tsv'), 'w') do |pte_file|
      pte_file.write("Passenger Transport Executive\tWikipedia URL\tContact category\tContact location type\tContact email\tNotes\n")
      PassengerTransportExecutive.find_each do |pte|
        if pte.pte_contacts.empty?
          pte_file.write([pte.name,
                          pte.wikipedia_url,
                          '',
                          '',
                          '',
                          ''].join("\t") + "\n")
        else
          pte.pte_contacts.each do |pte_contact|
            pte_file.write([pte.name,
                            pte.wikipedia_url,
                            pte_contact.category,
                            pte_contact.location_type,
                            pte_contact.email,
                            pte_contact.notes].join("\t") + "\n")
          end
        end
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
          if operator.operator_contacts.empty?
            operator_contact_file.write([operator.id,
                                         operator.name,
                                         operator.company_no,
                                         operator.registered_address,
                                         operator.url,
                                         '',
                                         '',
                                         '',
                                         '',
                                         operator.routes.count,
                                         operator_url(operator)].join("\t") + "\n")
          else
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
end