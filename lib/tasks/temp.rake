require File.dirname(__FILE__) +  '/data_loader'

namespace :temp do

  desc 'Create action confirmation models for existing actions' 
  task :populate_action_confirmations => :environment do 
    User.find_each() do |user|
      if user.post_login_action 
        user.post_login_action = user.post_login_action.to_sym
      end
      case user.post_login_action
      when :join_campaign
        campaign_supporter = CampaignSupporter.find_by_token(user.perishable_token)
        if campaign_supporter
          ActionConfirmation.create!(:user => user, 
                                     :token => user.perishable_token,
                                     :target => campaign_supporter)
        else
          ActionConfirmation.create!(:user => user, 
                                     :token => user.perishable_token)
          puts "missing campaign supporter: token #{user.perishable_token}"
        end
      when :add_comment
        comment = Comment.find_by_token(user.perishable_token)
        if comment
          ActionConfirmation.create!(:user => user, 
                                     :token => user.perishable_token,
                                     :target => comment)
        else
          ActionConfirmation.create!(:user => user, 
                                     :token => user.perishable_token)
          puts "missing comment: token #{user.perishable_token}"
        end
      when :create_problem
        problem = Problem.find_by_token(user.perishable_token)
        if problem
          ActionConfirmation.create!(:user => user, 
                                     :token => user.perishable_token,
                                     :target => problem)
        else
          ActionConfirmation.create!(:user => user, 
                                     :token => user.perishable_token)
          puts "missing problem: token #{user.perishable_token}"
        end
      else
        ActionConfirmation.create!(:user => user, 
                                   :token => user.perishable_token)
        puts "no post login action"
      end
    end
  end
  
end