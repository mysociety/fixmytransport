class Subscription < ActiveRecord::Base
  belongs_to :user 
  belongs_to :target, :polymorphic => true
  before_create :generate_confirmation_token
  
  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end
  
end