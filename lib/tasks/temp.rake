require File.dirname(__FILE__) +  '/data_loader'

namespace :temp do
  
  desc 'Backfill slugs for campaigns from the subdomains' 
  task :backfill_campaign_slugs => :environment do 
    Campaign.find_each(:conditions => ['subdomain is not null']) do |campaign|
      campaign.slugs.create :name => campaign.subdomain, :sluggable => campaign
    end
  end
  
end
