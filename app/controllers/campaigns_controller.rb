class CampaignsController < ApplicationController

  before_filter :process_map_params, :only => [:show]
  before_filter :find_campaign, :only => [:edit, :update]
  before_filter :find_confirmed_campaign, :only => [:show, :join, 
                                                    :leave, :add_update, 
                                                    :request_advice, :add_comment]
  before_filter :require_owner_or_token, :only => [:edit, :update]
  before_filter :require_owner, :only => [:add_update, :request_advice]
  before_filter :require_user, :only => [:add_comment]
  before_filter :find_update, :only => [:add_comment]
  
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
  
  def confirm_leave
    @campaign_supporter = CampaignSupporter.find_by_token(params[:email_token])
    if @campaign_supporter
      @campaign = @campaign_supporter.campaign
      @campaign.remove_supporter(@campaign_supporter.supporter)
    else
      @error = :error_on_leave
    end
  end
  
  def leave
    if current_user && params[:user_id] && current_user.id == params[:user_id].to_i
      @campaign.remove_supporter(current_user)
      flash[:notice] = t(:you_are_no_longer_a_supporter, :campaign => @campaign.title)
      redirect_to campaign_url(@campaign)
    end
    render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
    return false
  end
  
  def confirm_join
    @campaign_supporter = CampaignSupporter.find_by_token(params[:email_token])
    # GET request with token from confirmation email
    if request.get? 
      if @campaign_supporter
        @user = @campaign_supporter.supporter
        @campaign_supporter.confirm!
      else
        @error = :error_on_join
      end
    # POST request from form displayed on confirmation
    elsif request.put?
      if @campaign_supporter
        @user = @campaign_supporter.supporter
        @user.attributes = params[:user]
        @user.registered = true
        if @user.save 
          redirect_to campaign_url(@campaign_supporter.campaign)
        end
      else
        @error = :error_on_register
      end
    end
  end
  
  def show
    @title = @campaign.title
    map_params_from_location(@campaign.location.points, find_other_locations=false)
    if current_user && current_user == @campaign.initiator
      @campaign_update = CampaignUpdate.new(:campaign => @campaign, 
                                            :user => current_user)
    end
  end
  
  def update
    @campaign.attributes=(params[:campaign])
    @campaign.confirmed = true
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
    if @campaign.title.blank?
      @campaign.title = @campaign.problem.subject
    end
    if @campaign.description.blank?
      @campaign.description = @campaign.problem.description
    end
  end
  
  def add_update
    if request.post? 
      @campaign_update = @campaign.campaign_updates.build(params[:campaign_update])
      if @campaign_update.save
        if request.xhr? 
          render :json => { :html => render_to_string(:partial => 'campaign_event', :locals => { :event => @campaign_update, :always_show_commentbox => false })}
          return 
        else
          flash[:notice] = @campaign_update.is_advice_request? ? t(:advice_request_added) : t(:update_added)
        end
      end
      redirect_to campaign_url(@campaign)
    else
      @campaign_update = @campaign.campaign_updates.build(:is_advice_request => params[:is_advice_request],
                                                          :user_id => current_user.id)
    end
  end
  
  def add_comment
    if request.post? 
      @comment = @campaign_update.comments.build(params[:campaign_comment])
      if @comment.save
        if request.xhr? 
          render :json => { :html => render_to_string(:partial => 'update_comment', :locals => {:comment => @comment}),
                            :update_id => @comment.campaign_update_id }
          return
        end  
      end
      redirect_to campaign_url(@campaign, :anchor => "update_#{@comment.campaign_update_id}")
    end
  end
  
  private
  
  def find_campaign
    if params[:id].to_i.to_s == params[:id]
      @campaign = Campaign.find(params[:id])
    else 
      @campaign = Campaign.find_by_subdomain(params[:id])
    end
    unless @campaign
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    return true
  end
  
  # filter method for finding a confirmed campaign
  def find_confirmed_campaign
    found = find_campaign
    return false unless @campaign
    unless @campaign.confirmed
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    return true
  end
  
  def find_update
    update_param = (params[:update_id] or params[:campaign_comment][:campaign_update_id])
    @campaign_update = CampaignUpdate.find(update_param)
    if ! @campaign_update
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    return true
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
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
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