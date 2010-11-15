class SentEmail < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :campaign_update
  belongs_to :recipient, :class_name => "User"
end
