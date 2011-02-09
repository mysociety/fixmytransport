class CampaignUpdate < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :user
  belongs_to :incoming_message
  belongs_to :outgoing_message
  validates_presence_of :text
  has_many :comments, :as => :commented
  has_many :campaign_events, :as => :described
  named_scope :general, :conditions => ['incoming_message_id is null and outgoing_message_id is null']
  named_scope :unsent, :conditions => ['sent_at is null']

  def sort_date
    created_at
  end

  # Sendable updates - not sent 
  def self.sendable
    unsent.find(:all)
  end
  
end