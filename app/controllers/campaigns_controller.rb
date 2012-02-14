class CampaignsController < ApplicationController

  before_filter :process_map_params, :only => [:show]
  before_filter :find_visible_campaign, :except => [:confirm_join,
                                                    :confirm_leave,
                                                    :index]
  before_filter :require_campaign_initiator, :only => [:add_update, :request_advice,
                                                       :complete, :add_photos, :add_details, :share]
  before_filter :require_campaign_initiator_or_expert, :only => [:edit, :update]
  after_filter :update_campaign_users, :only => [:show]

  def show
    @commentable = @campaign
    @next_action_join = data_to_string({ :action => :join_campaign,
                                         :id => @campaign.id,
                                         :notice => t('campaigns.show.sign_in_to_join') })
    @title = @campaign.title
    map_params_from_location(@campaign.location.points,
                            find_other_locations=false,
                            height=CAMPAIGN_PAGE_MAP_HEIGHT,
                            width=CAMPAIGN_PAGE_MAP_WIDTH)
    @collapse_quotes = params[:unfold] ? false : true

    if current_user &&
       current_user.is_admin? &&
       current_user.can_admin_issues? &&
       params[:initiator_view] == '1'
      flash.now[:large_notice] = t('campaigns.show.showing_initiator_view')
    end
  end

  def index
    redirect_to(:controller => 'problems', :action => 'issues_index')
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

  def join
    if !request.post?
      redirect_to campaign_url(@campaign)
    else
      if current_user
        @campaign.add_supporter(current_user, confirmed=true)
        redirect_to campaign_url(@campaign)
      else
        # store the next action to the session
        join_data = { :action => :join_campaign,
                      :id => @campaign.id,
                      :notice => t('campaigns.show.sign_in_to_join') }
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
            @json[:redirect] = login_url
            @json[:notice] = join_data[:notice]
            render :json => @json
          end
        end
      end
    end
  end

  def leave
    if current_user
      @campaign.remove_supporter(current_user)
      flash[:notice] = t('campaigns.show.you_are_no_longer_a_supporter')
      redirect_to campaign_url(@campaign)
      return
    end
    render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
    return false
  end

  def confirm_leave
    @campaign_supporter = CampaignSupporter.find_by_token(params[:email_token])
    if @campaign_supporter
      @campaign = @campaign_supporter.campaign
      @campaign.remove_supporter(@campaign_supporter.supporter)
    else
      @error = 'campaigns.confirm_leave.error_on_leave'
    end
  end

  def complete
    old_status_code = @campaign.status_code
    @campaign.status = :fixed
    @campaign.send_questionnaire = false
    @campaign.save
    if current_user.answered_ever_reported?
      redirect_to campaign_url(@campaign)
    else
      flash[:old_status_code] = old_status_code
      redirect_to questionnaire_fixed_url(:id => @campaign.id, :type => 'Campaign')
    end
  end

  def add_details
    if request.post?
      if (@campaign.update_attributes(params[:campaign]))
        redirect_to campaign_url(@campaign)
      else
        render :action => "add_details"
      end
    else
      @campaign.title = nil
      @campaign.description = nil
    end
  end

  def add_photos
    if request.post?
      if @campaign.update_attributes(params[:campaign])
        redirect_to campaign_url(@campaign)
      else
        @campaign_photo = @campaign.campaign_photos.detect{ |photo| photo.new_record? }
        render :action => 'add_photos'
      end
    end
  end

  def add_update
    if request.post?
      @campaign_update = @campaign.campaign_updates.build(params[:campaign_update])
      @campaign_update.user = current_user
      if @campaign_update.save
        @campaign_event = @campaign.campaign_events.create!(:event_type => 'campaign_update_added',
                                                            :described => @campaign_update)
        respond_to do |format|
          format.html do
            flash[:notice] = @campaign_update.is_advice_request? ? t('campaigns.add_update.advice_request_added') : t('campaigns.add_update.update_added')
            redirect_to campaign_url(@campaign)
            return
          end
          format.json do
            index = params[:last_thread_index].to_i + 1
            render :json => { :success => true,
                              :html => render_to_string(:partial => 'campaign_event',
                                                        :locals => { :event => @campaign_event,
                                                                     :index => index})}
            return
          end
        end
      else
        respond_to do |format|
          format.html do
            render :action => "add_update"
          end
          format.json do
            @json = {}
            @json[:success] = false
            add_json_errors(@campaign_update, @json)
            render :json => @json
          end
        end
      end
    else
      @campaign_update = @campaign.campaign_updates.build(:is_advice_request => params[:is_advice_request])
    end
  end

  def get_supporters
    render :partial => "supporters", :locals => {:show_all => true}, :layout => false
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

  def facebook
    @body_class = "facebook-body"
  end

  private

  def require_campaign_initiator_or_expert
    return require_campaign_initiator(allow_expert=true)
  end

  # record that a user supporting or initiating a campaign has seen the campaign page.
  def update_campaign_users
    if current_user
      current_user.mark_seen(@campaign)
    end
  end

end