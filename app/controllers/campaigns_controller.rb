class CampaignsController < ApplicationController
  
  cache_sweeper :campaign_sweeper, :only => :confirm
  
  def new
    @title = t :new_campaign
    @campaign = Campaign.new()
  end
  
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
  
  def find
    @location_search = LocationSearch.new_search!(session_id, params)
    campaign_attributes = params[:campaign]
    campaign_attributes[:location_search] = @location_search
    @campaign = Campaign.new(campaign_attributes)
    if !@campaign.valid? 
      @title = t :new_campaign
      render :new
    else
      @campaign.location_from_attributes
      if @campaign.locations.size == 1
         redirect_to location_url(@campaign.locations.first)
      elsif !@campaign.locations.empty?
        @campaign.locations = @campaign.locations.sort_by(&:name)
        location_search.add_choice(@campaign.locations)
        @title = t :multiple_locations
        render :choose_location
      else
        @title = t :new_campaign
        render :new
      end
    end
  end
  
  def choose_location
  end
  
  def confirm
    @campaign = Campaign.find_by_token(params[:email_token])
    if @campaign
      @campaign.update_attribute(:confirmed, true)
    else
      @error = t(:campaign_not_found)
    end
  end
  
  def show
    @campaign = Campaign.find(params[:id])
    @title = @campaign.title
  end
  
  private
  
  rescue_from ActiveRecord::RecordNotFound do
    render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
  end
  
end