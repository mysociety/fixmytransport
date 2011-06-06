class CampaignSupporter < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :supporter, :class_name => 'User'
  before_create :generate_confirmation_token
  named_scope :confirmed, :conditions => ["confirmed_at is not null"], :order => "confirmed_at desc"
  
  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end
  
  def send_confirmation_email
    CampaignMailer.deliver_supporter_confirmation(supporter, self.campaign, token)
  end
  
  def confirmed? 
    !confirmed_at.blank?
  end
  
  def confirm!
    if self.confirmed_at.blank?
      self.confirmed_at = Time.now
      save!  
    end
  end
  
end
