class OutgoingMessage < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :author, :class_name => 'User'
  belongs_to :recipient, :polymorphic => :true
  belongs_to :incoming_message
  has_many :campaign_updates
  validate :recipient_in_existing_campaign_recipients, 
           :incoming_message_in_campaign_messages,
           :incoming_message_or_recipient
  validates_presence_of :campaign, :body, :subject

  has_status({ 0 => 'New', 
               1 => 'Sent', 
               2 => 'Hidden' })
                 
                 
  def after_initialize
    if self.body.nil?
      self.body = quoted_incoming_message
    end
    if self.subject.nil?
      self.subject = reply_to_incoming_subject
    end
  end
  
  def recipient_in_existing_campaign_recipients
    if recipient && !campaign.existing_recipients.include?(recipient)
      errors.add(:recipient, ActiveRecord::Error.new(self, :recipient, :invalid).to_s)
    end
  end
  
  def incoming_message_in_campaign_messages
    if incoming_message && !campaign.incoming_messages.include?(incoming_message)
      errors.add(:incoming_message, ActiveRecord::Error.new(self, :incoming_message, :invalid).to_s)
    end
  end
  
  def incoming_message_or_recipient
    if !incoming_message && !recipient
      errors.add(:base, ActiveRecord::Error.new(self, :base, :missing_recipient).to_s)
    end
  end
  
  def reply_email
    author.campaign_email_address(campaign)
  end
  
  def send_message
    CampaignMailer.deliver_outgoing_message(self)
    self.sent_at = Time.now
    self.save
  end
  
  def quoted_incoming_message
    if incoming_message
      return "\n\n-----Original Message-----\n\n#{incoming_message.body_for_quoting}\n"
    else
      return ""
    end
  end
  
  def reply_to_incoming_subject
    if incoming_message
      return "Re: #{incoming_message.subject}"
    else
      return ""
    end
  end
  
  def recipient_email
    if recipient
      return recipient.email
    elsif incoming_message
      return incoming_message.mail.from_addrs[0].address
    end
  end
  
  def recipient_name
    if recipient
      return recipient.name
    elsif incoming_message
      return incoming_message.mail.friendly_from
    else
      return nil
    end
  end
  
end