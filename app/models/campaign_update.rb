class CampaignUpdate < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :user
  belongs_to :incoming_message
  validates_presence_of :text
  named_scope :general, :conditions => ['incoming_message_id is null']

end