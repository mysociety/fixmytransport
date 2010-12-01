class IncomingMessagesController < ApplicationController
    
  before_filter :find_visible_campaign, :only => [:show, :show_attachment]
  
  def show
    @incoming_message = IncomingMessage.find(params[:id])
    if @campaign != @incoming_message.campaign 
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    if current_user && current_user == @incoming_message.campaign.initiator
      @campaign_update = CampaignUpdate.new(:incoming_message => @incoming_message, 
                                            :campaign => @campaign, 
                                            :user => current_user)
    end
    @collapse_quotes = params[:unfold] ? false : true
  end
  
  def show_attachment
    @incoming_message = IncomingMessage.find(params[:id])
    if @campaign != @incoming_message.campaign 
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    attachment = @incoming_message.find_attachment(params[:url_part_number].to_i)
    response.content_type = attachment.content_type
    render :text => attachment.body
  end
  
end