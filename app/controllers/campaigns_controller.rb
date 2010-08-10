class CampaignsController < ApplicationController
  
  cache_sweeper :campaign_sweeper, :only => :confirm
  
  def index
    @title = t(:recent_campaigns)
    @campaigns = Campaign.paginate( :page => params[:page], 
                                    :conditions => ['confirmed = ?', true],
                                    :order => 'created_at DESC' )
    if !@campaigns.empty? 
      @updated = @campaigns.first.updated_at
    end
    respond_to do |format|
      format.html
      format.atom { render :template => 'shared/campaigns.atom.builder', :layout => false }
    end
  end
  
  def show
    @campaign = Campaign.find(params[:id])
    @title = @campaign.title
  end
  
end