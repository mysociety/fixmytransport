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
  
  desc 'Transfer existing updates to campaign comments'
  task :transfer_updates_to_campaign_comments => :environment do
    Update.find_each do |update|
      puts update.inspect
      campaign_comment = CampaignComment.new(:problem_id   => update.problem_id, 
                                             :user_id      => update.reporter_id, 
                                             :text         => update.text, 
                                             :confirmed_at => update.confirmed_at, 
                                             :created_at   => update.created_at, 
                                             :updated_at   => update.updated_at, 
                                             :mark_fixed   => update.mark_fixed,
                                             :mark_open    => update.mark_open, 
                                             :token        => update.token,
                                             :user_name    => update.reporter_name)
      campaign_comment.save!
      campaign.status = update.status
      campaign_comment.token = update.token
      campaign_comment.save!
    end
  end
  
end