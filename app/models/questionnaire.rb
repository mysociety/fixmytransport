class Questionnaire < ActiveRecord::Base
  belongs_to :subject, :polymorphic => true
  belongs_to :user
  before_create :generate_token
  
  # Makes a random token, suitable for using in URLs
  def generate_token
    self.token = MySociety::Util.generate_token
  end
  
end