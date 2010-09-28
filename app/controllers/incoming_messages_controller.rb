class IncomingMessagesController < ApplicationController
  
  def show
    @incoming_message = IncomingMessage.find(params[:id])
  end
  
end