class OutgoingMessagesController < ApplicationController

  before_filter :find_confirmed_campaign, :only => [:new, :create]
  before_filter :require_campaign_initiator, :only => [:new, :create]
  
  def new
    @recipient = params[:recipient_type].constantize.find(params[:recipient_id])
    @outgoing_message = @campaign.outgoing_messages.build(:author => current_user, 
                                                          :recipient => @recipient)
  end
  
  def create
    @outgoing_message = @campaign.outgoing_messages.build(params[:outgoing_message])
    @recipient = @outgoing_message.recipient
    if @outgoing_message.save
      @outgoing_message.send_message
      flash[:notice] = t(:your_message_has_been_sent)
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