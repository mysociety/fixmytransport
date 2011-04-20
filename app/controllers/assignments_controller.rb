class AssignmentsController < ApplicationController
  
  before_filter :find_visible_campaign
  before_filter :require_expert, :only => [:new, :create]
  
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
  
  def show
    visible_assignments = [:write_to_other, 
                           :find_transport_organization,
                           :find_transport_organization_contact_details]
    @assignment = @campaign.assignments.find(params[:id])
    if ! visible_assignments.include?(@assignment.task_type.to_sym) 
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
  end
  
end