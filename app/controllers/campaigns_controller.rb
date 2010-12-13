class CampaignsController < ApplicationController

  before_filter :process_map_params, :only => [:show]
  before_filter :find_editable_campaign, :only => [:edit, :update]
  before_filter :find_visible_campaign, :only => [:show, :join, 
                                                  :leave, :add_update, 
                                                  :request_advice, :add_comment]
  before_filter :require_campaign_initiator_or_token, :only => [:edit, :update]
  before_filter :require_campaign_initiator, :only => [:add_update, :request_advice]
  before_filter :find_update, :only => [:add_comment]
  
  def index
    @campaigns = WillPaginate::Collection.create((params[:page] or 1), 10) do |pager|
      campaigns = Campaign.find_recent(pager.per_page, :offset => pager.offset)
      # inject the result array into the paginated collection:
      pager.replace(campaigns)

      unless pager.total_entries
        # the pager didn't manage to guess the total count, do it manually
        pager.total_entries = Campaign.visible.count
      end
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
      return
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
        @user.registered = false
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
    @campaign.confirm
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
        redirect_to campaign_url(@campaign)
        return
      else
        @empty_update = true
      end
    else
      @campaign_update = @campaign.campaign_updates.build(:is_advice_request => params[:is_advice_request],
                                                          :user_id => current_user.id)
    end
  end
  
  def confirm_comment
    @comment = Comment.find_by_token(params[:email_token])
    if @comment
      @comment.confirm!
    else
      @error = t(:update_not_found)
    end
  end
  
  def add_comment
    if request.post? 
      @comment = @campaign_update.comments.build(params[:comment])
      @comment.status = :new
      if params[:comment].has_key?(:user_id) && 
        current_user.id != params[:comment][:user_id].to_i
        raise "Comment added with user_id that isn't logged in user"
      end
      if @comment.valid?
        @comment.save_user
        @comment.save
        if current_user
          @comment.confirm!
        else
          @comment.send_confirmation_email
          @action = t(:your_update_will_not_be_posted)
          @worry = t(:holding_on_to_update)
          render 'shared/confirmation_sent'
          return
        end
        if request.xhr? 
          render :json => { :html => render_to_string(:partial => 'update_comment', 
                                                      :locals => {:comment => @comment}),
                            :update_id => @comment.campaign_update_id,
                            :success => true }
          return
        end  
        redirect_to campaign_url(@campaign, :anchor => "update_#{@comment.campaign_update_id}")
      else
        if request.xhr?
          @json = { :update_id => @comment.campaign_update_id,
                    :success => false }
          @json[:errors] = {}
          [@comment.errors, @comment.user.errors].each do |errors|
            errors.each do |attribute,message|
              @json[:errors][attribute] = message
            end
          end
          render :json => @json
        else
          @campaign_update.comments.delete(@comment)
          @empty_comment = true
        end
      end
      
    end
  end
  
  private
  
  def find_update
    update_param = (params[:update_id] or params[:comment][:campaign_update_id])
    @campaign_update = CampaignUpdate.find(update_param)
    if ! @campaign_update
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    return true
  end
  
  def require_campaign_initiator_or_token
    return require_campaign_initiator if @campaign.status != :new
    return true if current_user && current_user == @campaign.initiator
    # if campaign initiator not yet registered, allow access by token
    if params[:token] && params[:token] == @campaign.problem.token
      if !@campaign.initiator.registered? and !current_user
        return true
      else
        # user is registered, but person making request is logged in as someone else
        return require_campaign_initiator 
      end
    else
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
    end
    return false
  end

end