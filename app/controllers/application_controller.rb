# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'digest'

class ApplicationController < ActionController::Base
  # send exception mails
  include ExceptionNotification::Notifiable
  include MySociety::UrlMapper
  helper :all # include all helpers, all the time
  protect_from_forgery if :current_user # See ActionController::RequestForgeryProtection for details
  skip_before_filter :verify_authenticity_token, :unless => :current_user

  before_filter :redirect_asset_host_requests,
                :make_cachable,
                :check_mobile_domain,
                :require_beta_password

  helper_method :location_search,
                :main_url,
                :admin_url,
                :current_user_session,
                :current_user,
                :instantiate_location,
                :stop_cache_path
  url_mapper # See MySociety::UrlMapper
  # Scrub sensitive parameters from the log
  filter_parameter_logging :password, :password_confirmation

  private

  def redirect_asset_host_requests
    if request.host.starts_with?('assets')
      domain = MySociety::Config.get("DOMAIN", request.host_with_port)
      main_host_request = request.protocol + domain + request.request_uri
      redirect_to main_host_request, :status => :moved_permanently
    end
  end

  def make_cachable
    return if MySociety::Config.getbool('STAGING_SITE', true)
    unless current_user
      expires_in 60.seconds, :public => true
      response.headers['Vary'] = 'Cookie'
    end
  end

  def long_cache
    return if MySociety::Config.getbool('STAGING_SITE', true)
    unless current_user
      expires_in 60.minutes, :public => true
      response.headers['Vary'] = 'Cookie'
    end
  end

  def current_user_session(refresh=false)
    return @current_user_session if (defined?(@current_user_session) && ! refresh)
    @current_user_session = UserSession.find
  end

  def current_user(refresh=false)
    return @current_user if (defined?(@current_user) && ! refresh)
    @current_user = current_user_session(refresh) && current_user_session.record
  end

  # filter method for requiring a logged-in user
  def require_user
    unless current_user
      store_location
      access_message_key = 'shared.access.access_this_page'
      flash[:notice] = t('shared.login.must_be_logged_in', :requested_action => t(access_message_key))
      redirect_to new_user_session_url
      return false
    end
    if current_user && current_user.suspended?
      flash[:error] = t('shared.suspended.forbidden')
      current_user_session.destroy
      redirect_to root_url
      return false
    end
  end

  # filter method for requiring no logged-in user
  def require_no_user
    if current_user
      store_location
      respond_to do |format|
        format.html do
          flash[:notice] = t('shared.login.must_be_logged_out')
          redirect_to root_url
          return false
        end
        format.json do
          @json = {:errors => {}}
          @json[:errors][:base] = t('shared.login.modal_must_be_logged_out')
          @json[:success] = false
          render :json => @json
          return false
        end
      end
    end
  end

  # filter method for finding an editable campaign (not neccessarily visible)
  def find_editable_campaign
    @campaign = Campaign.find(params[campaign_param()])
    unless @campaign && @campaign.editable?
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    return true
  end

  def campaign_param
    if self.class == CampaignsController
      param = :id
    else
      param = :campaign_id
    end
    return param
  end

  # filter method for finding a visible campaign
  def find_visible_campaign
    found = find_editable_campaign
    return false unless found
    unless @campaign.visible?
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    # if this isn't the latest slug, redirect to the latest
    if request.get? && !@campaign.friendly_id_status.best?
      redirect_to params.merge({campaign_param() => @campaign }), :status => :moved_permanently
    end
    return true
  end

  def require_expert
    return true if current_user && current_user.is_expert?
    @access_message = access_message_key
    @name = t('shared.login.a_fixmytransport_boffin')
    return redirect_bad_user
  end

  # filter method for requiring that the campaign initiator be logged in
  def require_campaign_initiator(allow_expert=false)
    if current_user && current_user == @campaign.initiator
      # set a flag so that if the user logs out here, we don't try and bring them back
      @no_redirect_on_logout = true
      return true
    end
    if allow_expert
      return true if current_user && current_user.is_expert?
    end
    @access_message = access_message_key
    @name = @campaign.initiator.name
    return redirect_bad_user
  end

  def redirect_bad_user
    respond_to do |format|
      format.html do
        store_location
        if current_user
          render :template => "shared/wrong_user"
          return false
        end
        flash[:notice] = t('shared.login.login_to', :user => @name, :requested_action => t(@access_message))
        redirect_to login_url
        return false
      end
      format.json do
        @json = {}
        @json[:success] = false
        @json[:requires_login] = true
        @json[:message] = t('shared.login.login_to', :user => @name, :requested_action => t(@access_message))
        render :json => @json
      end
    end
  end

  def store_location
    if request.get?
      session[:return_to] = request.request_uri
    end
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def access_message_key
    "shared.access.#{controller_name}_#{@action_name}_access_message"
  end

  # Currently logged in user, otherwise
  # for administration interface, return display name of authenticated user.
  def user_for_edits
    if current_user
      return current_user
    else
      return "*unknown*";
    end
  end

  def user_for_paper_trail
    user_for_edits
  end

  def location_search
    @location_search ||= LocationSearch.find_current(session_id)
  end

  def session_id
    # Have to load session by requesting a value in order to read session id
    # https://rails.lighthouseapp.com/projects/8994/tickets/2268-rails-23-session_optionsid-problem
    session[:foo]
    request.session_options[:id]
  end

  # make sure user data is cleared
  def handle_unverified_request
    super
    cookies.delete 'user_credentials'
    @current_user_session = @current_user = nil
  end

  def data_to_string(data)
    yaml_data = YAML::dump(data)
    string = ActiveSupport::Base64.encode64(yaml_data)
  end

  def string_to_data(string)
    yaml_data = ActiveSupport::Base64.decode64(string)
    data = YAML::load(yaml_data)
  end

  # Store data in the session about an incomplete action that the user
  # will need to log in to complete
  def save_post_login_action_to_session
    if post_login_action_data = get_action_data(params)
      session[:next_action] = params[:next_action]
      if post_login_action_data[:action] == :join_campaign
        flash.now[:notice] = post_login_action_data[:notice]
      end
    end
  end

  # Move data about an incomplete action (that the user will need to log in to
  # complete) from the session to the database. Store any model as unconfirmed,
  # and link it to an action confirmation model. Should be called when a user initiates
  # some login action that may be completed in another session as it has an email step
  # e.g. account creation, password reset
  def save_post_login_action_to_database(user)
    if post_login_action_data = get_action_data(session)
      session.delete(:next_action)
      id = post_login_action_data[:id]
      user.post_login_action = post_login_action_data[:action].to_s
      user.save_without_session_maintenance
      confirmation_target = nil
      case post_login_action_data[:action]
      when :join_campaign
        campaign = Campaign.find(id)
        confirmation_target = campaign.add_supporter(user, confirmed=false, token=user.perishable_token)
        return_model = campaign
      when :add_comment
        commented_type = post_login_action_data[:commented_type]
        commented = commented_type.constantize.find(id)
        comment_data = { :text => post_login_action_data[:text],
                         :mark_fixed => post_login_action_data[:mark_fixed],
                         :mark_open => post_login_action_data[:mark_open],
                         :model => commented,
                         :confirmed => false,
                         :text_encoded => post_login_action_data[:text_encoded] }
        comment = Comment.create_from_hash(comment_data, user, token=user.perishable_token)
        confirmation_target = comment
        return_model = comment
      when :create_problem
        problem = Problem.create_from_hash(post_login_action_data, user, token=user.perishable_token)
        confirmation_target = problem
        return_model = problem
      end
      ActionConfirmation.create!(:user => user,
                                 :token => user.perishable_token,
                                 :target => confirmation_target)
      return return_model
    else
      # just add an action confirmation without target so the user can log in with
      # their current token
      ActionConfirmation.create!(:user => user,
                                 :token => user.perishable_token)
      return nil
    end

  end

  # Get a string from the session data about an incomplete action that can be
  # used to tell the user why they should go and click on the link in their email
  def post_login_action_string
    if post_login_action_data = get_action_data(session)
      case post_login_action_data[:action]
      when :join_campaign
        return t('shared.confirmation_sent.you_will_not_be_a_supporter')
      when :add_comment
        return t('shared.confirmation_sent.your_comment_will_not_be_added')
      when :create_problem
        return t('shared.confirmation_sent.your_problem_will_not_be_created')
      else
        return nil
      end
    end
  end

  # Get a string from the session data about an incomplete action that can be
  # used to tell the user we'll hold on to their content while they go and check
  # their email
  def post_login_action_worry
    if post_login_action_data = get_action_data(session)
      case post_login_action_data[:action]
      when :join_campaign
        return nil
      when :add_comment
        return t('shared.confirmation_sent.well_hold_on_to_your_comment')
      when :create_problem
        return t('shared.confirmation_sent.well_hold_on_to_your_problem')
      else
        return nil
      end
    end
  end

  # Unserialize the data from the session about an incomplete action
  def get_action_data(data_hash)
    if data_hash[:next_action]
      next_action_data = string_to_data(data_hash[:next_action])
      if next_action_data.is_a?(Hash) and ActionConfirmation.actions.include?(next_action_data[:action])
        return next_action_data
      end
    end
    return nil
  end

  # If a user started an action anonymously that requires being logged in, and then
  # logged in, get their action information out of the session, and complete the action.
  def perform_post_login_action
    current_user(refresh=true)
    if post_login_action_data = get_action_data(session)
      id = post_login_action_data[:id]
      case post_login_action_data[:action]
      when :join_campaign
        campaign = Campaign.find(id)
        campaign.add_supporter(current_user, confirmed=true)
        session[:return_to] = campaign_path(campaign)
      when :add_comment
        commented_type = post_login_action_data[:commented_type]
        commented = commented_type.constantize.find(id)
        comment_data = { :model => commented,
                         :text => post_login_action_data[:text],
                         :mark_fixed => post_login_action_data[:mark_fixed],
                         :mark_open => post_login_action_data[:mark_open],
                         :confirmed => true,
                         :text_encoded => post_login_action_data[:text_encoded] }
        comment = Comment.create_from_hash(comment_data, current_user)
        flash[:notice] = t('shared.add_comment.thanks_for_comment')
        next_url = get_comment_next_url(comment)
        respond_to do |format|
          format.html{ session[:return_to] = next_url }
          format.json{ @json[:redirect] = next_url }
        end
      when :create_problem
        problem = Problem.create_from_hash(post_login_action_data, current_user)
        next_url = convert_problem_url(problem)
        respond_to do |format|
          format.html{ session[:return_to] = next_url }
          format.json{ @json[:redirect] = next_url }
        end
      end
      session.delete(:next_action)
    end
  end

  # If a user started an action anonmyously that requires being logged-in and then logged in
  # in a way that we assume they may complete in a separate session as they have an
  # email confirmation step (e.g. account creation, password reset),
  # complete their initial action.
  # a false return value indicates that a redirect has been performed
  def perform_saved_login_action
    case @action_confirmation.target
    when CampaignSupporter
      @action_confirmation.target.confirm!
      session[:return_to] = campaign_path(@action_confirmation.target.campaign)
      flash[:notice] = t('accounts.confirm.successfully_confirmed_support')
    when Comment
      comment = @action_confirmation.target
      if comment.status == :new && comment.created_at < (Time.now - 1.month)
        flash[:error] = t('accounts.confirm.comment_token_expired')
        redirect_to(root_url)
        return false
      else
        comment.confirm!
        session[:return_to] = get_comment_next_url(comment)
        if self.controller_name == "password_resets"
          flash[:notice] = t('password_resets.update.successfully_confirmed_comment')
        else
          flash[:notice] = t('accounts.confirm.successfully_confirmed_comment')
        end
      end
    when Problem
      problem = @action_confirmation.target
      if problem.status == :new && problem.created_at < (Time.now - 1.month)
        flash[:error] = t('accounts.confirm.problem_token_expired')
        redirect_to(root_url)
        return false
      else
        if problem.status == :new
          if self.controller_name == "password_resets"
            flash[:notice] = t('password_resets.update.successfully_confirmed_problem_first_time')
          else
            flash[:notice] = t('accounts.confirm.successfully_confirmed_problem_first_time')
          end
        else
          if self.controller_name == "password_resets"
            flash[:notice] = t('password_resets.update.successfully_confirmed_problem')
          else
            flash[:notice] = t('accounts.confirm.successfully_confirmed_problem')
          end
        end
        session[:return_to] = convert_problem_url(problem)
      end
    end
    return true
  end

  def add_json_errors(model_instance, json_hash)
    json_hash[:errors] = {}
    model_instance.errors.each do |attribute,message|
      json_hash[:errors][attribute] = message
    end
  end

  def allowed_location_types
    ['BusRoute',
     'FerryRoute',
     'TrainRoute',
     'TramMetroRoute',
     'Route',
     'StopArea',
     'Stop',
     'SubRoute',
     'CoachRoute']
  end

  # Turn a location id and type from params into a model
  def instantiate_location(location_id, location_type)
    if allowed_location_types.include?(location_type)
      return location_type.constantize.find(:first, :conditions => ['id = ?', location_id])
    else
      return nil
    end
  end

  def instantiate_location_by_code(code, location_type)
    if location_type == 'Stop'
      return Stop.find_by_atco_code(code)
    else
      return nil
    end
  end

  def process_map_params
    @zoom = params[:zoom].to_i if params[:zoom] && (MIN_ZOOM_LEVEL <= params[:zoom].to_i && params[:zoom].to_i <= MAX_VISIBLE_ZOOM)
    @lon = params[:lon].to_f if params[:lon]
    @lat = params[:lat].to_f if params[:lat]

    # reset map params if outside GB
    if (@lat && @lon) && (@lat > BNG_MAX_LAT || @lat < BNG_MIN_LAT || @lon < BNG_MIN_LON || @lon > BNG_MAX_LON)
      @lat = nil
      @lon = nil
    end
  end

  # set the lat, lon and zoom based on the locations being shown, and find other locations
  # within the bounding box
  def map_params_from_location(locations, find_other_locations=false, height=MAP_HEIGHT, width=MAP_WIDTH, options=nil)
    @find_other_locations = find_other_locations
    # check for an array of routes
    if locations.first.is_a?(Route) && !locations.first.show_as_point
      locations = locations.map{ |location| location.points }.flatten
    end

    # in order to show an appropriately zoomed map area, include locality children of
    # a single area type location
    if options && options[:mode] == :browse
      if [Locality, District, AdminArea].include?(locations.first.class) && locations.size == 1
        locations = Locality.find_with_descendants(locations.first)
      end
    end
    lons = locations.map{ |element| element.lon }
    lats = locations.map{ |element| element.lat }
    unless @lon
      @lon = lons.inject(0){ |sum, lon| sum + lon } / lons.size
    end
    unless @lat
      @lat = lats.inject(0){ |sum, lat| sum + lat } / lats.size
    end
    unless @zoom
      @zoom = Map::zoom_to_coords(lons.min, lons.max, lats.min, lats.max, height, width)
    end
    if find_other_locations
      map_data = Map.other_locations(@lat, @lon, @zoom, height, width, @highlight)
      @other_locations = map_data[:locations]
      @issues_on_map = map_data[:issues]
      @nearest_issues = map_data[:nearest_issues]
      @distance = map_data[:distance]
    else
      @other_locations = []
      @issues_on_map = []
      @nearest_issues = []
    end
  end

  # handle a posted comment if there is a current user
  def handle_comment_current_user
      render_or_return_for_invalid_comment and return false
  end

  # handle a posted comment if there's no current user logged in
  def handle_comment_no_user
      render_or_return_for_invalid_comment and return false
  end

  def render_or_return_for_invalid_comment
    respond_to do |format|
      format.html do
        render :template => 'shared/add_comment'
      end
      format.json do
        @json = {}
        @json[:success] = false
        add_json_errors(@comment, @json)
        render :json => @json
      end
    end
  end

  def get_comment_next_url(comment)
    if comment.needs_questionnaire?
      # store the old status code of the commented issue for use in the
      # questionnaire
      flash[:old_status_code] = comment.old_commented_status_code
      return questionnaire_fixed_url(:id => comment.commented.id,
                                     :type => comment.commented.class.to_s)
    else
      return commented_url(comment.commented)
    end
  end

  # wrapper for easier access to method from controller specs
  def commented_url(commented)
    @template.commented_url(commented)
  end

  def commented_type_description(commented)
    case commented
    when Stop
     return 'stop'
    when StopArea
     return StopAreaType.generic_name_for_type(commented.area_type)[:singular]
    when Route
     return 'route'
    when SubRoute
     return 'route'
    when Campaign
     return 'issue'
    when Problem
     return 'problem report'
    else
     raise "Unknown commented type: #{commented.class}"
    end
  end

  # Path to cache file for a stop with a given suffix. Adds a directory into the path
  # for the first letter of the locality, in order to spread the directories and not hit the
  # ext3 32,000 links per inode limit
  def stop_cache_path(stop, suffix=nil)
    locality_slug = stop.locality.to_param
    domain = MySociety::Config.get("DOMAIN", '127.0.0.1:3000')
    stop_path = "#{domain}/stops/#{locality_slug[0].chr}/#{locality_slug}/#{stop.to_param}"
    if suffix
      stop_path = "#{stop_path}.action_suffix=#{suffix}"
    end
    stop_path
  end

  def app_status
    MySociety::Config.get('APP_STATUS', 'live')
  end

  def require_beta_password
    if app_status == 'closed_beta'
      beta_username = MySociety::Config.get('BETA_USERNAME', 'username')
      beta_password = MySociety::Config.get('BETA_PASSWORD', 'password')
      authenticate_or_request_with_http_basic('Closed Beta') do |username, password|
        username == beta_username && Digest::MD5.hexdigest(password) == beta_password
      end
    end
  end

  def check_mobile_domain
    mobile_domain = MySociety::Config.get('MOBILE_DOMAIN', '')
    if !mobile_domain.blank?
      if request.host == mobile_domain
        render :template => 'shared/mobile_placeholder', :layout => 'mobile'
      end
    end
  end

  def recognized_devices
    ['android', 'iphone', 'ipad']
  end

  # later, more thorough user-agent sniffing would be appropriate
  # or idealy just pick it up from, e.g., request.headers["X-device-class"], set by varnish
  # sets up @user_device and @is_mobile
  # also: might not realy be using vary headers like this, but OK for now to show intent
  def get_device_from_user_agent
    mobile_devices = recognized_devices() # see keyword search below
    x_header_name = MySociety::Config.get('DEVICE_TYPE_X_HEADER', '')
    if !x_header_name.blank?
      response.headers['Vary'] = x_header_name
      @user_device = request.headers[x_header_name]
      if @user_device.blank?
        @user_device = :default_device
      end
      @is_mobile = mobile_devices.include?(@user_device)
    else
      response.headers['Vary'] = 'User-Agent'
      @user_device = :default_device
      @is_mobile = false
      user_agent =  request.env['HTTP_USER_AGENT'].downcase
      mobile_devices.each do |keyword| # for now, just lazy search for keywords; later may be more complex
        if user_agent.index(keyword)
          @user_device = keyword
          @is_mobile = true
          break
        end
      end
    end
  end

  def load_user_using_action_confirmation_token
    @action_confirmation = ActionConfirmation.find_by_token(params[:email_token], :include => :user)
    if @action_confirmation
      @account_user = @action_confirmation.user
    end
    if ! @account_user
      flash[:error] = t('accounts.confirm.could_not_find_account')
      redirect_to root_url
    end
    if @account_user && @account_user.suspended? # disallow attempts to confirm from suspended acccounts
      flash[:error] = t('shared.suspended.forbidden')
      redirect_to root_url
    end
    if @account_user && current_user && @account_user != current_user
      flash[:notice] = t('shared.login.must_be_logged_out')
      redirect_to root_url
    end
  end

end
