class CampaignEvent < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :described, :polymorphic => true
  validates_inclusion_of :event_type, :in => ['problem_report_sent', 
                                              'outgoing_message_sent', 
                                              'incoming_message_received', 
                                              'campaign_update_added', 
                                              'assignment_given', 
                                              'assignment_completed', 
                                              'comment_added']
  
  after_initialize :set_visibility
  
  def set_visibility
    case self.event_type
    when 'assignment_completed'
      # all assignment completions are visible except problem publishing
      if self.described.task_type_name == 'publish-problem'
        self.visible = false
      else 
        self.visible = true
      end
    when 'comment_added'
      # comments currently only on things that already have visible events
      self.visible = false
    when 'campaign_update_added'
      # only general campaign updates are visible 
      if self.described.incoming_message or self.described.outgoing_message
        self.visible = false
      else
        self.visible = true
      end
    else  
      self.visible = true
    end
  end
                                          
end
