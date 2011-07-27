class Subscription < ActiveRecord::Base
  belongs_to :user 
  belongs_to :target, :polymorphic => true
  before_create :generate_confirmation_token
  named_scope :confirmed, :conditions => ["confirmed_at is not null"], :order => "confirmed_at desc"
  

  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end
  
  def confirm!
    if self.confirmed_at.blank?
      self.confirmed_at = Time.now
      save!  
    end
  end
  
  def self.find_for_user_and_target(user, target_id, target_type)
    find(:first, :conditions => ['target_id = ? AND target_type = ? AND user_id = ?', 
                                  target_id, target_type, user.id])
  end
  
end