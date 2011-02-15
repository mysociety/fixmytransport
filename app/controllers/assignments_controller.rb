class AssignmentsController < ApplicationController
  
  before_filter :find_visible_campaign
  before_filter :require_expert
  
  def new
    @initiator = @campaign.initiator
    reason =  t(:default_reason_text, :user => @initiator.first_name,
                                      :expert => current_user.name)
    @assignment = @campaign.assignments.build(:user => @initiator, :data => {:reason => reason})
  end
  
  def create
    @initiator = @campaign.initiator  
    assignment_data = { :name => params[:name], 
                        :email => params[:email], 
                        :draft_text => params[:draft_text], 
                        :reason => params[:reason], 
                        :subject => params[:subject] }
    assignment_attributes = { :user => @initiator, 
                              :creator => current_user,
                              :problem => @campaign.problem,
                              :campaign => @campaign,
                              :status => :new, 
                              :task_type_name => 'write-to-other', 
                              :data => assignment_data }
    @assignment = Assignment.assignment_from_attributes(assignment_attributes)                          
    if @assignment.save
      # send an email to the campaign initiator
      CampaignMailer.deliver_write_to_other_assignment(@assignment, params[:subject])
      # add an event to the campaign
      @campaign.campaign_events.create!(:event_type => 'assignment_given',
                                        :described => @assignment)
      flash[:notice] = t(:sent_your_advice, :user => @initiator.name)
      redirect_to campaign_path(@campaign)
    else
      render :new
      return
    end

  end
  
end