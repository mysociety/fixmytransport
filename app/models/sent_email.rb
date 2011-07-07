class SentEmail < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :campaign_update
  belongs_to :comment
  belongs_to :problem
  belongs_to :recipient, :polymorphic => true
end
