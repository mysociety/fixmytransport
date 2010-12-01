namespace :temp do
  desc 'Backfill confirmed_at field for campaigns' 
  task :backfill_campaign_confirmed_at => :environment do 
    Campaign.find_each(:conditions => ["confirmed = ?", true]) do |campaign|
      puts campaign.inspect
      campaign.confirmed_at = campaign.created_at
      campaign.status = :confirmed
      campaign.save!
    end
  end
  
end