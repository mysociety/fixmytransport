class IncomingMessagesController < ApplicationController
    
  def show
    @incoming_message = IncomingMessage.find(params[:id])
    if ! @incoming_message.campaign.confirmed? 
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
  end
  
  def show_attachment
    @incoming_message = IncomingMessage.find(params[:id])
    if ! @incoming_message.campaign.confirmed? 
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    attachment = @incoming_message.find_attachment(params[:url_part_number].to_i)
    response.content_type = attachment.content_type
    render :text => attachment.body
  end
  
end