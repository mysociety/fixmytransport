class CampaignComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :campaign_update
  belongs_to :campaign
  validates_presence_of :text
end
