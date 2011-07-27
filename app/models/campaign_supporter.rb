class CampaignSupporter < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :supporter, :class_name => 'User'
  before_create :generate_confirmation_token
  named_scope :confirmed, :conditions => ["confirmed_at is not null"], :order => "confirmed_at desc"
  
  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end
    
  def confirmed? 
    !confirmed_at.blank?
  end
  
  def confirm!
    if self.confirmed_at.blank?
      self.confirmed_at = Time.now
      save!  
    end
    # look for any subscription to the campaign for this user
    subscription = Subscription.find_for_user_and_target(self.supporter, self.campaign.id, 'Campaign')
    subscription.confirm! if subscription
    self
  end
  
end
