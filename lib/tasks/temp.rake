require File.dirname(__FILE__) +  '/data_loader'

namespace :temp do
  
  desc 'Backfill slugs for campaigns from the subdomains' 
  task :backfill_campaign_slugs => :environment do 
    Campaign.find_each(:conditions => ['subdomain is not null']) do |campaign|
      campaign.slugs.create :name => campaign.subdomain, :sluggable => campaign
    end
  end
  
  desc 'Set confirmed_password flag to true on all users where registered flag is true'
  task :set_confirmed_password => :environment do 
    User.find_each(:conditions => ['registered = ?', true]) do |user|
      user.confirmed_password = true
      user.save_without_session_maintenance
    end
  end
  
end
