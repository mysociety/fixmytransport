class AssignmentsController < ApplicationController

  before_filter :find_visible_campaign
  before_filter :require_expert, :only => [:new, :create]
  before_filter :require_campaign_initiator, :only => [:edit, :update]

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
                        :description => params[:description],
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

  def update
    @assignment = @campaign.assignments.find(params[:id])
    if ! editable_assignments.include?(@assignment.task_type.to_sym)
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    @assignment.data = { :organization_name => params[:organization_name],
                         :organization_email => params[:organization_email] }
    @assignment.status = :in_progress
    if @assignment.save
      flash[:notice] = t(:confirming_organization)
      CampaignMailer.deliver_completed_assignment(@campaign, @assignment)
      @campaign.campaign_events.create!(:event_type => 'assignment_in_progress',
                                        :described => @assignment)
      # if they added a contact, complete that assignment
      # if they didn't, and we don't know, that needs to be added as an assignment
      redirect_to campaign_path(@campaign)
    else
      render :edit
      return
    end
  end

  def edit
    @assignment = @campaign.assignments.find(params[:id])
    if ! editable_assignments.include?(@assignment.task_type.to_sym)
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
  end

  def show
    visible_assignments = [:write_to_other]
    @assignment = @campaign.assignments.find(params[:id])
    if ! visible_assignments.include?(@assignment.task_type.to_sym)
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
  end

  private

  def editable_assignments
    [:find_transport_organization, :find_transport_organization_contact_details]
  end

end