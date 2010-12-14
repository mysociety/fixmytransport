class Comment < ActiveRecord::Base
  belongs_to :user
  # belongs_to :campaign_update
  # belongs_to :problem
  belongs_to :commented, :polymorphic => true
  validates_presence_of :text, :user_name
  validates_associated :user
  before_create :generate_confirmation_token
  before_validation_on_create :populate_user_name
  
  has_paper_trail
  has_status({ 0 => 'New', 
               1 => 'Confirmed', 
               2 => 'Hidden' })
               
  named_scope :visible, :conditions => ["status_code = ?", self.symbol_to_status_code[:confirmed]], :order => "confirmed_at desc"
  
  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end
  
  def send_confirmation_email
    if commented.is_a? Problem
      ProblemMailer.deliver_comment_confirmation(user, self, token)
    else
      CampaignMailer.deliver_comment_confirmation(user, self, token)
    end
  end
  
  def populate_user_name
    if self.user and ! self.user_name
      self.user_name = self.user.name
    end
  end
  
  # create the user if it doesn't exist, but don't save it yet
  def user_attributes=(attributes)
    if !attributes[:id].blank?
      self.user = User.find(attributes[:id])
    else
      self.user = User.find_or_initialize_by_email(attributes[:email], :name => user_name)
    end
  end
  
  def save_user
    user.save_if_new
  end
  
  def confirm!
    return unless self.status == :new
    self.status = :confirmed
    self.confirmed_at = Time.now
    if commented.is_a? Problem 
      if mark_fixed
        commented.status = :fixed
      end
      commented.updated_at = Time.now
      commented.save!
    end
    save!  
  end
  
end
