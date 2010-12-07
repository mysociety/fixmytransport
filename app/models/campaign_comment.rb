class CampaignComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :campaign_update
  belongs_to :campaign
  validates_presence_of :text, :user_name
  validates_associated :user
  before_create :generate_confirmation_token
  
  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end
  
  def send_confirmation_email
    CampaignMailer.deliver_comment_confirmation(user, self, token)
  end
  
  has_status({ 0 => 'New', 
               1 => 'Confirmed', 
               2 => 'Hidden' })
               
  named_scope :visible, :conditions => ["status_code = ?", self.symbol_to_status_code[:confirmed]], :order => "confirmed_at desc"
  
  # create the user if it doesn't exist, but don't save it yet
  def user_attributes=(attributes)
    self.user = User.find_or_initialize_by_email(attributes[:email], :name => user_name)
  end
  
  def save_user
    user.save_if_new
  end
  
  def confirm!
    return unless self.status == :new
    self.status = :confirmed
    self.confirmed_at = Time.now
    save!  
  end
  
end
