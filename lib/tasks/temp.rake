namespace :temp do
  desc 'Backfilling campaign events'
  task :backfill_campaign_events => :environment do 
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.record_timestamps = false
      
      IncomingMessage.find_each do |incoming_message|
        incoming_message.campaign.campaign_events.create!(:event_type => 'incoming_message_received',
                                                          :described => incoming_message, 
                                                          :created_at => incoming_message.created_at,
                                                          :updated_at => incoming_message.created_at)
      end
      
      OutgoingMessage.find_each(:conditions => 'sent_at is not null') do |outgoing_message|
        outgoing_message.campaign.campaign_events.create!(:event_type => 'outgoing_message_sent', 
                                                          :described => outgoing_message, 
                                                          :created_at => outgoing_message.sent_at,
                                                          :updated_at => outgoing_message.sent_at)
      end
      
      CampaignUpdate.find_each do |campaign_update|
        campaign_update.campaign.campaign_events.create!(:event_type => 'campaign_update_added', 
                                                         :described => campaign_update, 
                                                         :created_at => campaign_update.created_at, 
                                                         :updated_at => campaign_update.created_at)
      
      end
      
      Assignment.find_each do |assignment|
        if assignment.status == :complete and assignment.problem.campaign
          assignment.problem.campaign.campaign_events.create!(:event_type => 'assignment_completed', 
                                                              :described => assignment, 
                                                              :created_at => assignment.updated_at, 
                                                              :updated_at => assignment.updated_at)
        end
      end
      
      Comment.find_each do |comment|
        if comment.status == :confirmed and comment.commented.campaign
          comment.commented.campaign.campaign_events.create!(:event_type => 'comment_added', 
                                                             :described => comment, 
                                                             :created_at => comment.confirmed_at, 
                                                             :updated_at => comment.confirmed_at)
        end
      end  
    end
  end
end
