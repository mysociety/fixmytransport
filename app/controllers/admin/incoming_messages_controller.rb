class Admin::IncomingMessagesController < Admin::AdminController

  before_filter :find_incoming
  before_filter :require_can_admin_organizations
  
  def show
  end
  
  def download
    response.content_type = 'message/rfc822'
    render :text => @incoming_message.raw_email.data
  end
  
  def destroy
    campaign = @incoming_message.campaign
    if @incoming_message.destroy
      flash[:notice] = t('admin.incoming_message_destroyed')
      if campaign
        campaign.campaign_events.create!(:event_type => 'incoming_message_deleted',
                                         :data => { :user => user_for_edits,
                                                    :deleted_id => @incoming_message.id })

      
        redirect_to admin_url(admin_campaign_path(campaign.id))
      else
        redirect_to admin_url(admin_root_path)
      end
    else
      flash.now[:error] = t('admin.incoming_message_destroy_problem')
      render :show
    end
  end
  
  def redeliver
    begin
      destination_campaign = Campaign.find(params[:campaign_id])
    rescue ActiveRecord::RecordNotFound => error      
      flash[:error] = "Failed to find destination campaign '#{params[:campaign_id]}'"
      redirect_to admin_url(admin_incoming_message_path(@incoming_message))
      return
    end
    campaign = @incoming_message.campaign
    @incoming_message.update_attribute('campaign_id', destination_campaign.id)
    destination_campaign.campaign_events.create!(:event_type => 'incoming_message_received', 
                                                 :described => @incoming_message)
    recipient = destination_campaign.get_recipient(@incoming_message.from)
    CampaignMailer.deliver_new_message(recipient, @incoming_message, destination_campaign)
    if campaign
      campaign.campaign_events.create!(:event_type => 'incoming_message_redelivered', 
                                       :described => @incoming_message, 
                                       :data => { :user => user_for_edits })
    end
    flash[:notice] = t('admin.incoming_message_moved')
    redirect_to admin_url(admin_campaign_path(destination_campaign.id))
  end
  
  private
  
  def find_incoming
    @incoming_message = IncomingMessage.find(params[:id])
  end
  
end