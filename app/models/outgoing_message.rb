class OutgoingMessage < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :author, :class_name => 'User'
  belongs_to :recipient, :polymorphic => :true
  has_many :campaign_updates
  validate :recipient_in_existing_campaign_recipients
  validates_presence_of :campaign, :body, :subject

  has_status({ 0 => 'New', 
               1 => 'Sent', 
               2 => 'Hidden' })
                 
  def recipient_in_existing_campaign_recipients
    if !campaign.existing_recipients.include?(recipient)
      errors.add(:recipient, ActiveRecord::Error.new(self, :recipient, :invalid).to_s)
    end
  end

end