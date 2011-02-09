class OutgoingMessage < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :author, :class_name => 'User'
  belongs_to :recipient, :polymorphic => :true
  belongs_to :incoming_message
  belongs_to :assignment
  has_many :campaign_updates
  validate :recipient_in_existing_campaign_recipients, 
           :incoming_message_in_campaign_messages,
           :incoming_message_or_recipient_or_assignment
  validates_presence_of :campaign, :body, :subject

  has_status({ 0 => 'New', 
               1 => 'Sent', 
               2 => 'Hidden' })
  
  def sort_date
    created_at
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
  
  def incoming_message_or_recipient_or_assignment
    if !incoming_message && !recipient && !assignment
      errors.add(:base, ActiveRecord::Error.new(self, :base, :missing_recipient).to_s)
    end
  end
  
  def reply_name_and_email
    author.campaign_name_and_email_address(self.campaign)
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
    elsif assignment
      return assignment.data[:email]
    end
  end
  
  def recipient_name
    if recipient
      return recipient.name
    elsif incoming_message
      return incoming_message.from
    elsif assignment 
      return assignment.data[:name]
    else
      return nil
    end
  end
  
  # class methods
  def self.message_from_attributes(campaign, user, attrs)
    message = self.new(:campaign => campaign,
                       :author => user)
    if attrs[:recipient_type] and attrs[:recipient_id]
      message.recipient = attrs[:recipient_type].constantize.find(attrs[:recipient_id])
    elsif attrs[:incoming_message_id]
      incoming_message = campaign.incoming_messages.find(attrs[:incoming_message_id])
      message.incoming_message = incoming_message
      message.body = message.quoted_incoming_message
      message.subject = message.reply_to_incoming_subject
    elsif attrs[:assignment_id]
      assignment = campaign.assignments.find(attrs[:assignment_id])
      message.assignment = assignment
      message.body = assignment.data[:draft_text]
    end
    message
  end
  
end