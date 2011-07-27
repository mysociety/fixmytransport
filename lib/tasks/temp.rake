require File.dirname(__FILE__) +  '/data_loader'

namespace :temp do

  desc 'Add some operators that had ambiguous codes'
  task :add_operators_for_ambiguous_codes => :environment do
    # BL - Badgerline now First Somerset & Avon
    # FC00 - In Wales will be First Cymru
    # MN - In London is Arriva London
    # KIM - In East Midlands, Kimes
    # ML - In London, Metroline
    # FL - First Leeds
    # SIH - In East Anglia is Stagecoach in Huntingdonshire
    # AM - In the East Midlands is Arriva Midlands
    # IF - East London in London
    # BCC - Diamond Bus (was Birmingham Coach Co.)
    mappings = { 'BL' => 'First Somerset & Avon',
                 'FC00' => 'First Cymru',
                 'MN' => 'Arriva London',
                 'KIM' => 'Kimes',
                 'ML' => 'Metroline Travel',
                 'FL' => 'First Leeds',
                 # 'FCH' => 'First in Calderdale and Huddersfield', # not all of them anymore
                 'SIF' => 'Stagecoach in Huntingdonshire',
                 'YRB' => 'First Bradford',
                 'AM' => 'Arriva Midlands',
                 # 'IF' => 'East London Bus & Coach', # not all
                 'BCC' => 'Diamond Bus',
                 'NX' => 'National Express',
                 '2222' => 'Arriva North West',
                 'MT00' => 'Morris Travel (Carmathenshire)',
                 'LC' => 'London Central',
                 'RB00' => 'Richards Bros',
                 '2079' => 'Rossendale Transport',
                 '2383' => 'Arriva Merseyside',
                 }
    mappings.each do |code, operator_name|
      operator = Operator.find_by_name(operator_name)
      routes = Route.find(:all, :conditions => ['operator_code = ?
                                                 AND id not in (SELECT route_id FROM route_operators)', code])
      routes.each do |route|
        puts "#{operator.name} #{route.description}"
        route.route_operators.create!(:operator => operator)
      end
    end
  end

  desc 'Transfer PTEs to use PTE contacts model to store contact information'
  task :transfer_ptes_to_contacts => :environment do
    PassengerTransportExecutive.find(:all).each do |pte|
      contact = pte.pte_contacts.create!(:category => 'Other', :email => pte.email)
      pte.sent_emails.each do |sent_email|
        sent_email.recipient = contact
        sent_email.save!
      end
      pte.outgoing_messages.each do |outgoing_message|
        outgoing_message.recipient = contact
        outgoing_message.save!
      end
    end
  end

  desc 'Mark problem subscriptions as confirmed'
  task :mark_problem_subscriptions_confirmed => :environment do
    Subscription.find(:all).each do |subscription|
      subscription.confirmed_at = subscription.created_at
      subscription.save!
    end
  end

  desc 'Create campaign subscriptions'
  task :create_campaign_subscriptions => :environment do
    CampaignSupporter.find(:all).each do |campaign_supporter|
      subscription = Subscription.create!(:target => campaign_supporter.campaign,
                                          :user => campaign_supporter.supporter,
                                          :confirmed_at => campaign_supporter.confirmed_at)
      subscription.update_attribute('token', campaign_supporter.token)
    end
  end

end

