class CampaignEvent < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :described, :polymorphic => true
  validates_inclusion_of :event_type, :in => ['outgoing_message_sent', 
                                              'incoming_message_received', 
                                              'incoming_message_deleted',
                                              'incoming_message_redelivered',
                                              'campaign_update_added', 
                                              'assignment_given', 
                                              'assignment_completed', 
                                              'comment_added',
                                              'assignment_in_progress', 
                                              'problem_report_resent']
  
  serialize :data
  named_scope :visible, :conditions => ["visible = ?", true], :order => 'created_at desc'
  before_validation :set_visibility
  after_save :update_campaign_latest_event_at
  
  def as_json(options={})
    return super({ :only => [:id, :event_type, :created_at], :methods => [:title] })
  end
  
  def update_campaign_latest_event_at
    if self.visible
      self.campaign.update_attribute('latest_event_at', self.created_at)
    end
  end
  
  def set_visibility
    if self.event_type == 'assignment_completed' && ['write-to-other'].include?(self.described.task_type_name)
      self.visible = false
    elsif ['incoming_message_deleted', 'incoming_message_redelivered'].include?(self.event_type) 
      self.visible = false
    else
      self.visible = true
    end
    return true
  end
  
  def title
    case event_type
    when 'incoming_message_received'
      I18n.translate('campaigns.show.got_a_message', :sender => self.described.safe_from, 
                                                     :campaigner => self.campaign.initiator.name)
    when 'outgoing_message_sent'
      I18n.translate('campaigns.show.wrote_a_message', :sender => self.described.author.name, 
                                                       :recipient => self.described.recipient_name, 
                                                       :assignment_text => self.described.assignment_text) 
    when 'assignment_completed'
      if self.described.task_type == 'publish_problem'
        I18n.translate('campaigns.show.reported_issue', :name => self.described.user_name)
      elsif self.described.task_type == 'write_to_transport_organization'
        I18n.translate('campaigns.show.wrote_to_orgs', :orgs => self.described.data[:organizations].map{ |organization| organization[:name] }.to_sentence, 
                                                       :name => self.described.user.name)
      end
    when 'assignment_given'
      I18n.translate('campaigns.show.expert_advised_writing', :expert => self.described.creator.name, 
                                                 :user => self.described.user.first_name, 
                                                 :recipient => self.described.data[:name], 
                                                 :advised => I18n.translate('campaigns.show.advised'))
    when 'assignment_in_progress'
      I18n.translate('campaigns.show.responsible_org_found', :user_name => self.described.user.name,  
                                                             :location => self.described.campaign.location.readable_type) 
    when 'campaign_update_added'
      I18n.translate(self.described.update_text, :name => self.described.user.name)
    when 'comment_added'
      self.described.header
    when 'problem_report_resent'
      I18n.translate('campaigns.show.problem_report_resent', :recipients => self.data[:sent_emails].map{ |sent_email_id| SentEmail.find(sent_email_id).recipient.name}.uniq.to_sentence)
    end
  end
  
end
