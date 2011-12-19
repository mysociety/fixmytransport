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
  attr_accessible :is_advice_request, :text, :incoming_message_id, :outgoing_message_id
  has_paper_trail

  # set attributes to include and exclude when performing model diffs
  diff :exclude => [:updated_at]

  def user_name
    self.user.name
  end

  # Return a list of version models in cronological order representing changes made
  # in the admin interface to this campaign update
  def admin_actions
    self.versions.find(:all, :conditions => ['admin_action = ?', true])
  end

  # Sendable updates - not sent
  def self.sendable
    unsent.find(:all)
  end

end