class CampaignUpdate < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :user
  belongs_to :incoming_message
  validates_presence_of :text
  has_many :comments, :class_name => 'CampaignComment'
  named_scope :general, :conditions => ['incoming_message_id is null']
  named_scope :unsent, :conditions => ['sent_at is null']

  # Sendable updates - not sent 
  def self.sendable
    unsent.find(:all)
  end
  
end