class CampaignsController < ApplicationController

  before_filter :process_map_params, :only => [:show]
  before_filter :find_campaign, :only => [:show, :edit, :update, :join, :leave]
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
  
  def join
    if request.post? 
      if current_user && params[:user_id] && current_user.id == params[:user_id].to_i
        # don't need to send a confirmation mail - already logged in
        @campaign.add_supporter(current_user, confirmed=true)
        flash[:notice] = t(:you_are_a_supporter, :campaign => @campaign.title)
        redirect_to campaign_url(@campaign)
      elsif params[:email]
        @user = User.find_or_initialize_by_email(params[:email])
        if @user.valid? 
          # save the user account if it doesn't exist, but don't log it in
          @user.save_if_new
          @campaign.add_supporter(@user, confirmed=false)
          @action = t(:you_will_not_be_a_supporter, :campaign => @campaign.title)
          render 'shared/confirmation_sent'
        else 
          render :join
        end
      end
    end
  end
  
  def leave
    if current_user && params[:user_id] && current_user.id == params[:user_id].to_i
      @campaign.remove_supporter(current_user)
      flash[:notice] = t(:you_are_no_longer_a_supporter, :campaign => @campaign.title)
      redirect_to campaign_url(@campaign)
    end
  end
  
  def confirm_join
    @campaign_supporter = CampaignSupporter.find_by_token(params[:email_token])
    if @campaign_supporter
      @campaign_supporter.confirm!
    else
      @error = t(:update_not_found)
    end
  end
  
  def show
    @title = @campaign.title
    map_params_from_location(@campaign.location.points, find_other_locations=false)
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
          store_location
          render :template => "campaigns/wrong_user"
          return false
        else
          return true
        end
      else
        flash[:notice] = t(:login_to_confirm, :user => @campaign.initiator.name)
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
    flash[:notice] = t(:login_to_edit, :user => @campaign.initiator.name)
    store_location
    redirect_to login_url
    return false
  end
  
end