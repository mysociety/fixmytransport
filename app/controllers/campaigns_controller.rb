class CampaignsController < ApplicationController

  before_filter :process_map_params, :only => [:show]
  before_filter :find_editable_campaign, :only => [:edit, :update]
  before_filter :find_visible_campaign, :except => [:index,
                                                    :confirm_join, :confirm_leave,
                                                    :update, :edit,
                                                    :confirm_comment]
  before_filter :require_campaign_initiator, :only => [:add_update, :request_advice,
                                                       :complete, :add_photos]
  before_filter :require_campaign_initiator_or_expert, :only => [:edit, :update]
  after_filter :update_campaign_supporter, :only => [:show]

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
      if current_user
        @campaign.add_supporter(current_user, confirmed=true)
        redirect_to campaign_url(@campaign)
      else
        # store the next action to the session
        join_data = { :action => :join_campaign,
                      :id => @campaign.id,
                      :redirect => campaign_path(@campaign),
                      :notice => "Please login or signup to join this campaign" }
        session[:next_action] = data_to_string(join_data)
        respond_to do |format|
          format.html do
            flash[:notice] = join_data[:notice]
            redirect_to login_url
          end
          format.json do
            @json = {}
            @json[:success] = true
            @json[:requires_login] = true
            @json[:notice] = join_data[:notice]
            render :json => @json
          end
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
        @user.name = params[:user][:name]
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
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

  def complete
    @campaign.status = :successful
    @campaign.save
    redirect_to campaign_url(@campaign)
  end

  def add_photos
    if request.post?
      if @campaign.update_attributes(params[:campaign])
        redirect_to campaign_url(@campaign)
      else
        render :action => 'add_photos'
      end
    else
      @campaign.campaign_photos.build({})
    end
  end

  def show
    @commentable = @campaign
    @next_action_join = data_to_string({ :action => :join_campaign,
                                         :id => @campaign.id,
                                         :redirect => campaign_path(@campaign),
                                         :notice => "Please login or create an account to join this campaign" })
    @title = @campaign.title
    map_params_from_location(@campaign.location.points,
                            find_other_locations=false,
                            height=CAMPAIGN_PAGE_MAP_HEIGHT,
                            width=CAMPAIGN_PAGE_MAP_WIDTH)
  end

  def get_supporters
    render :partial => "supporters", :locals => {:show_all => true}, :layout => false
  end

  def update
    @campaign.attributes=(params[:campaign])
    if @campaign.save
      redirect_to campaign_url(@campaign)
    else
      render :edit
    end
  end

  def edit
  end

  def add_update
    if request.post?
      @campaign_update = @campaign.campaign_updates.build(params[:campaign_update])
      if @campaign_update.save
        @campaign_event = @campaign.campaign_events.create!(:event_type => 'campaign_update_added',
                                                            :described => @campaign_update)
        if request.xhr?
          render :json => { :html => render_to_string(:partial => 'campaign_event', :locals => { :event => @campaign_event })}
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
    @commentable = @campaign
    if request.post?
      @comment = @campaign.comments.build(params[:comment])
      @comment.status = :new
      if current_user
        return handle_comment_current_user
      else
        return handle_comment_no_user
      end
    end
    render :template => 'shared/add_comment'
  end

  private

  def require_campaign_initiator_or_expert
    return require_campaign_initiator(allow_expert=true)
  end
  
  # record that a user supporting a campaign has seen the campaign page.
  def update_campaign_supporter
    if current_user && current_user.new_supporter?(@campaign)
      current_user.mark_seen(@campaign)
    end
  end

end