require File.dirname(__FILE__) +  '/data_loader'
require "#{RAILS_ROOT}/app/helpers/application_helper"
namespace :data do

  include DataLoader

  def tokenize(text)
    text.split(/[^a-zA-Z]/)
  end

  def get_problems
    problems = []
    Problem.find_recent_issues(nil).each do |issue|
      if issue.is_a?(Problem)
        problems << issue
      else
        problems << issue.problem
      end
    end
    problems
  end

  desc 'Produce a list of the most apologetic operators'
  task :all_apologies => :environment do

    apologies = ['sorry', 'apologies', 'apologise']
    frequencies = {'Operator' => {},
                   'Council' => {},
                   'PassengerTransportExecutive' => {}}
    IncomingMessage.find_each do |message|
      words = tokenize(message.body_for_quoting)
      print "."
      words.each do |word|
        if apologies.include?(word)
          problem = message.campaign.problem
          problem.responsibilities.each do |responsibility|

            organization = responsibility.organization_type.constantize.find_by_id(responsibility.organization_id)
            if !frequencies[responsibility.organization_type].has_key?(responsibility.organization_id)

              frequencies[responsibility.organization_type][responsibility.organization_id] = {:name => organization.name,
                                                                                               :count => 1}
            else
              frequencies[responsibility.organization_type][responsibility.organization_id][:count] += 1
            end
          end
        end
      end
    end
    frequencies.each do |organization_type, org_freqs|
      org_freqs.each do |org_id, org_data|
        total_problems = Responsibility.count(:all, :conditions => ['organization_type = ? and organization_id = ?',
                                                                    organization_type, org_id])
        org_data[:count_per_report] = org_data[:count].to_f / total_problems.to_f
      end
      org_freqs.sort_by { |x,y| y[:count_per_report] }.each { |org_id,org_data| puts "#{org_data[:name]} #{org_data[:count_per_report]}"}
    end
  end

  desc 'Produce some word count statistics'
  task :word_counts => :environment do
    stopwords = 'a,able,about,across,after,all,almost,also,am,among,an,and,any,are,as,at,be,because,been,but,by,can,cannot,could,dear,did,do,does,either,else,ever,every,for,from,get,got,had,has,have,he,her,hers,him,his,how,however,i,if,in,into,is,it,its,just,least,let,like,likely,may,me,might,most,must,my,neither,no,nor,not,of,off,often,on,only,or,other,our,own,rather,said,say,says,she,should,since,so,some,than,that,the,their,them,then,there,these,they,this,tis,to,too,twas,us,wants,was,we,were,what,when,where,which,while,who,whom,why,will,with,would,yet,you,your'
    stopwords = stopwords.split(',')
    frequencies = Hash.new(0)
    problems = get_problems
    problems.each do |problem|
      words = tokenize(problem.subject + problem.description)
      words.each do |word|
        unless ( word.blank? || stopwords.include?(word) )
          frequencies[word] += 1
        end
      end
    end
    frequencies.sort_by { |x,y| y }.each { |w,f| puts "#{w} #{f}"}
  end

  desc 'Return the most reported on places'
  task :most_reported_places => :environment do
    locations = { 'Stop' => {},
                  'StopArea' => {},
                  'Route' => {},
                  'SubRoute' => {} }
    problems = get_problems
    problems.each do |problem|
      location_type = problem.location_type
      location_id = problem.location_id
      if !locations[location_type].has_key?(location_id)
        locations[location_type][location_id] = 1
      else
        locations[location_type][location_id] += 1
      end
    end
    locations.each do |location_type, type_data|
      puts location_type
      locations[location_type].sort_by { |x,y| y }.each do |location_id, frequency|
        puts "#{location_type.constantize.find(location_id).name} #{frequency}"
      end
    end
  end

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
      Problem.find_recent_issues(nil).each do |issue|
        if issue.is_a?(Problem)
          problem = issue
        else
          problem = issue.problem
        end
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
                   issue.status,
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