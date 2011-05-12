class CampaignEvent < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :described, :polymorphic => true
  validates_inclusion_of :event_type, :in => ['outgoing_message_sent', 
                                              'incoming_message_received', 
                                              'campaign_update_added', 
                                              'assignment_given', 
                                              'assignment_completed', 
                                              'comment_added',
                                              'assignment_in_progress']
  
  named_scope :visible, :conditions => ["visible = ?", true], :order => 'created_at desc'
  before_validation :set_visibility
  after_save :update_campaign_latest_event_at
  
  def update_campaign_latest_event_at
    self.campaign.update_attribute('latest_event_at', self.created_at)
  end
  
  def set_visibility
    if self.event_type == 'assignment_completed' && ['write-to-other'].include?(self.described.task_type_name)
      self.visible = false
    else
      self.visible = true
    end
    return true
  end

end
