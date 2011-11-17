class CampaignUpdate < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :user
  belongs_to :incoming_message
  belongs_to :outgoing_message
  validates_presence_of :text
  has_many :comments, :as => :commented, :order => 'confirmed_at asc'
  has_many :campaign_events, :as => :described
  named_scope :general, :conditions => ['incoming_message_id is null and outgoing_message_id is null']
  named_scope :unsent, :conditions => ['sent_at is null']
  has_paper_trail

  def user_name
    self.user.name
  end
  
  def update_text
    if self.is_advice_request?
      text = 'campaigns.show.user_requested_advice'
    else
      text = 'campaigns.show.added_an_update'
    end
    return text
  end

  # Sendable updates - not sent 
  def self.sendable
    unsent.find(:all)
  end
  
end