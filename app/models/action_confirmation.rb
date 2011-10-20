class ActionConfirmation < ActiveRecord::Base
  belongs_to :user
  validates_uniqueness_of :token
  belongs_to :target, :polymorphic => true
  
  def self.actions
    [:join_campaign, :add_comment, :create_problem]
  end
  
end