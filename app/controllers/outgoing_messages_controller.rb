class OutgoingMessagesController < ApplicationController

  before_filter :find_visible_campaign, :only => [:new, :create, :show]
  before_filter :require_campaign_initiator, :only => [:new, :create]

  def new
    @outgoing_message = OutgoingMessage.message_from_attributes(@campaign, current_user, params)
    if !@outgoing_message.incoming_message_or_recipient_or_assignment
      redirect_to campaign_url(@campaign)
    end
  end
  
  def create
    @outgoing_message = @campaign.outgoing_messages.build(params[:outgoing_message])
    if @outgoing_message.save
      if @outgoing_message.assignment and @outgoing_message.assignment.status != :complete
        @outgoing_message.assignment.complete!
      end
      @outgoing_message.send_message
      flash[:notice] = t('outgoing_messages.new.your_message_has_been_sent')
      redirect_to campaign_outgoing_message_path(@campaign, @outgoing_message)
    else
      render :action => 'new'
    end
  end
  
  def show
    @outgoing_message = OutgoingMessage.find(params[:id])
    if current_user && current_user == @outgoing_message.campaign.initiator
      @campaign_update = CampaignUpdate.new(:outgoing_message => @outgoing_message, 
                                            :campaign => @campaign, 
                                            :user => current_user)
    end
  end
  
end