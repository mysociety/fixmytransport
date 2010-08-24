class CampaignsController < ApplicationController
  
  cache_sweeper :campaign_sweeper, :only => :confirm
  before_filter :find_campaign, :only => [:show, :edit, :update]
  before_filter :require_owner_or_token, :only => [:edit, :update]
  
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
    @title = @campaign.title
  end
  
  def update
    @campaign.attributes=(params[:campaign])
    if params[:user] and params[:token] == @campaign.problem.token
      @campaign.initiator.attributes=(params[:user])
      @campaign.initiator.registered = true
    end
    if @campaign.valid? 
      @campaign.save && @campaign.initiator.save
      redirect_to campaign_url(@campaign)
    else
      render :edit
    end
  end
  
  def edit
  end
  
  private
  
  def find_campaign
    @campaign = Campaign.find(params[:id])
  end
  
  def require_owner_or_token
    return require_owner if @campaign.status != :new
    return true if current_user && current_user == @campaign.initiator
    
    # if campaign initiator not yet registered, allow access by token
    if params[:token] && params[:token] == @campaign.problem.token
      if !@campaign.initiator.registered?
        if current_user
          render :template => "wrong_user"
          return false
        else
          return true
        end
      else
        flash[:notice] = "Login as #{@campaign.initiator.name} to confirm this campaign"
        store_location
        redirect_to login_url
        return false
      end
    else
      render :file => "#{Rails.root}/public/404.html", :status => :not_found
    end
    return false
  end
  
  def require_owner
    return true if current_user && current_user == @campaign.initiator
    flash[:notice] = "Login as #{@campaign.initiator.name} to edit this campaign"
    store_location
    redirect_to login_url
    return false
  end
  
end