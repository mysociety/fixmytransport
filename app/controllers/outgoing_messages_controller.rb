class OutgoingMessagesController < ApplicationController

  before_filter :find_confirmed_campaign, :only => [:new]
  before_filter :require_campaign_initiator, :only => [:new]
  
  def new
    
  end
  
  def create
  end
  
  def show
  end
  
end