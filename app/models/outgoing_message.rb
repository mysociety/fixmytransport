class OutgoingMessage < ActiveRecord::Base

  include FixMyTransport::Status

  belongs_to :campaign
  belongs_to :author, :class_name => 'User'
  belongs_to :recipient, :polymorphic => :true
  belongs_to :incoming_message
  belongs_to :assignment
  has_many :campaign_updates
  has_many :campaign_events, :as => :described
  validate :recipient_in_existing_campaign_recipients,
           :incoming_message_in_campaign_messages,
           :incoming_message_or_recipient_or_assignment
  validates_presence_of :campaign, :body, :subject
  attr_accessible :subject, :body, :recipient_id, :recipient_type, :incoming_message_id, :assignment_id

  has_status({ 0 => 'New',
               1 => 'Sent',
               2 => 'Hidden' })

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
      return false
    end
    return true
  end

  def reply_name_and_email
    author.campaign_name_and_email_address(self.campaign)
  end

  def send_message
    ActiveRecord::Base.transaction do
      self.sent_at = Time.now
      CampaignMailer.deliver_outgoing_message(self)
      self.save!
      self.campaign.campaign_events.create!(:event_type => 'outgoing_message_sent',
                                            :described => self)
    end
  end

  def quoted_incoming_message
    if incoming_message
      return "\n\n-----#{I18n.translate('outgoing_messages.new.original_message')}-----\n\n#{incoming_message.body_for_quoting}\n"
    else
      return ""
    end
  end

  def reply_to_incoming_subject
    if incoming_message
      return "#{I18n.translate('outgoing_messages.new.re')}: #{incoming_message.subject}"
    else
      return ""
    end
  end

  def recipient_email
    if recipient
      return recipient.email
    elsif incoming_message
      return incoming_message.mail.from_or_sender_address
    elsif assignment
      return assignment.data[:email]
    end
  end

  def recipient_name
    if recipient
      return recipient.name
    elsif incoming_message
      return incoming_message.safe_from
    elsif assignment
      return assignment.data[:name]
    else
      return nil
    end
  end

  # returns the assignment that this message completed (if any)
  def completed_assignment
    if self.assignment and self.assignment.status == :complete
      assignment_first_message = OutgoingMessage.find(:first, :conditions => ['assignment_id = ?', self.assignment],
                                                              :order => 'created_at asc')
      if self == assignment_first_message
        return self.assignment
      end
    end
    return nil
  end

  def self.allowed_recipients
    ['PassengerTransportExecutiveContact', 'OperatorContact', 'CouncilContact']
  end

  # class methods
  def self.message_from_attributes(campaign, user, attrs)
    message = self.new
    message.campaign = campaign
    message.author = user
    if attrs[:recipient_type] and attrs[:recipient_id] and self.allowed_recipients.include?(attrs[:recipient_type])
      message.recipient = attrs[:recipient_type].constantize.find(attrs[:recipient_id])
    elsif attrs[:incoming_message_id]
      incoming_message = campaign.incoming_messages.find(attrs[:incoming_message_id])
      message.incoming_message = incoming_message
      message.body = message.quoted_incoming_message
      message.subject = message.reply_to_incoming_subject
    elsif attrs[:assignment_id]
      assignment = campaign.assignments.find(attrs[:assignment_id])
      message.assignment = assignment
      # don't show the draft text if this recipient has already been written to
      if assignment.status != :complete
        message.body = assignment.data[:draft_text]
      end
    end
    message
  end

end