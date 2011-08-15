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
                :get_device_from_user_agent,
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
  end

  # filter method for requiring no logged-in user
  def require_no_user
    if current_user
      store_location
      flash[:notice] = t('shared.login.must_be_logged_out')
      redirect_to root_url
      return false
    end
  end

  # filter method for finding an editable campaign (not neccessarily visible)
  def find_editable_campaign
    if self.class == CampaignsController
      param = :id
    else
      param = :campaign_id
    end
    @campaign = Campaign.find(params[param])
    unless @campaign && @campaign.editable?
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    return true
  end

  # filter method for finding a visible campaign
  def find_visible_campaign
    found = find_editable_campaign
    return false unless found
    unless @campaign.visible?
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
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
    return true if current_user && current_user == @campaign.initiator
    if allow_expert
      return true if current_user && current_user.is_expert?
    end
    @access_message = access_message_key
    @name = @campaign.initiator.name
    return redirect_bad_user
  end

  def redirect_bad_user
    store_location
    if current_user
      render :template => "shared/wrong_user"
      return false
    end
    flash[:notice] = t('shared.login.login_to', :user => @name, :requested_action => t(@access_message))
    redirect_to login_url
    return false
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
    elsif request.env["REMOTE_USER"]
      return request.env["REMOTE_USER"]
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

  def save_post_login_action_to_session
    if post_login_action_data = get_action_data(params)

      session[:next_action] = params[:next_action]
      if post_login_action_data[:action] == :join_campaign
        flash.now[:notice] = post_login_action_data[:notice]
      end
    end
  end

  def save_post_login_action_to_database(user)
    if post_login_action_data = get_action_data(session)
      session.delete(:next_action)
      id = post_login_action_data[:id]
      user.post_login_action = post_login_action_data[:action].to_s
      user.save_without_session_maintenance
      case post_login_action_data[:action]
      when :join_campaign
        campaign = Campaign.find(id)
        campaign.add_supporter(user, confirmed=false, token=user.perishable_token)
        return campaign
      when :add_comment
        commented_type = post_login_action_data[:commented_type]
        commented = commented_type.constantize.find(id)
        comment = Comment.add(user,
                              commented,
                              post_login_action_data[:text],
                              post_login_action_data[:mark_fixed],
                              post_login_action_data[:mark_open],
                              confirmed=false, token=user.perishable_token)
        return comment
      when :create_problem
        problem = Problem.create_from_hash(post_login_action_data, user, token=user.perishable_token)
        return problem
      end
    end

  end

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

  def post_login_actions
    [:join_campaign, :add_comment, :create_problem]
  end

  def get_action_data(data_hash)
    if data_hash[:next_action]
      next_action_data = string_to_data(data_hash[:next_action])
      if next_action_data.is_a?(Hash) and post_login_actions.include?(next_action_data[:action])
        return next_action_data
      end
    end
    return nil
  end

  def perform_post_login_action
    current_user(refresh=true)
    if post_login_action_data = get_action_data(session)
      id = post_login_action_data[:id]
      case post_login_action_data[:action]
      when :join_campaign
        campaign = Campaign.find(id)
        campaign.add_supporter(current_user, confirmed=true)
      when :add_comment
        commented_type = post_login_action_data[:commented_type]
        commented = commented_type.constantize.find(id)
        Comment.add(current_user,
                    commented,
                    post_login_action_data[:text],
                    post_login_action_data[:mark_fixed],
                    post_login_action_data[:mark_open],
                    confirmed=true)
        flash[:notice] = t('shared.add_comment.thanks_for_comment')
      when :create_problem
        problem = Problem.create_from_hash(post_login_action_data, current_user)
        respond_to do |format|
          format.json do
            @json[:redirect] = convert_problem_url(problem)
          end
          format.html do
            session[:return_to] = convert_problem_url(problem)
          end
        end
      end
      if post_login_action_data[:redirect]
        session[:return_to] = post_login_action_data[:redirect]
      end
      session.delete(:next_action)
    end
  end

  def add_json_errors(model_instance, json_hash)
    json_hash[:errors] = {}
    model_instance.errors.each do |attribute,message|
      json_hash[:errors][attribute] = message
    end
  end

  # Turn a location id and type from params into a model
  def instantiate_location(location_id, location_type)
    allowed_types = ['BusRoute',
                     'FerryRoute',
                     'TrainRoute',
                     'TramMetroRoute',
                     'Route',
                     'StopArea',
                     'Stop',
                     'SubRoute',
                     'CoachRoute',
                     ]
    if allowed_types.include?(location_type)
      return location_type.constantize.find(:first, :conditions => ['id = ?', location_id])
    else
      return nil
    end
  end

  def process_map_params
    @zoom = params[:zoom].to_i if params[:zoom] && (MIN_ZOOM_LEVEL <= params[:zoom].to_i && params[:zoom].to_i <= MAX_VISIBLE_ZOOM)
    @lon = params[:lon].to_f if params[:lon]
    @lat = params[:lat].to_f if params[:lat]
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
    @comment.user = current_user
    if @comment.valid?
      @comment.save
      @comment.confirm!
      respond_to do |format|
        format.html do
          flash[:notice] = t('shared.add_comment.thanks_for_comment')
          redirect_to @template.commented_url(@comment.commented)
        end
        format.json do
          index = params[:last_thread_index].to_i + 1
          comment_html = render_to_string :partial => "shared/comment",
                                          :locals => { :comment => @comment,
                                                       :index => index }
          @json = { :success => true,
                    :html => "<li>#{comment_html}</li>",
                    :mark_fixed => @comment.mark_fixed,
                    :mark_open => @comment.mark_open }
          render :json => @json
        end
      end
    else
      render_or_return_for_invalid_comment and return false
    end
  end

  # handle a posted comment if there's no current user logged in
  def handle_comment_no_user
    @comment.skip_name_validation = true
    if @comment.valid?
      commented_type = @comment.commented_type
      comment_data = { :action => :add_comment,
                       :id => @comment.commented_id,
                       :commented_type => commented_type,
                       :text => @comment.text,
                       :mark_fixed => @comment.mark_fixed,
                       :mark_open => @comment.mark_open,
                       :redirect => @template.commented_url(@comment.commented),
                       :notice => t('shared.add_comment.sign_in_to_comment',
                                    :commented_type => commented_type_description(@comment.commented)) }
      session[:next_action] = data_to_string(comment_data)
      respond_to do |format|
        format.html do
          flash[:notice] = comment_data[:notice]
          redirect_to(login_url)
        end
        format.json do
          @json = { :success => true,
                    :requires_login => true,
                    :notice => comment_data[:notice] }
          render :json => @json
        end
      end
    else
      render_or_return_for_invalid_comment and return false
    end
  end

  def render_or_return_for_invalid_comment
    respond_to do |format|
      format.html do
        render :action => 'add_comment'
      end
      format.json do
        @json = {}
        @json[:success] = false
        add_json_errors(@comment, @json)
        render :json => @json
      end
    end
  end

  def commented_type_description(commented)
    case commented
    when Stop
     return 'stop'
    when StopArea
     if StopAreaType.station_types.include?(commented.area_type)
       return 'station'
     elsif StopAreaType.bus_station_types.include?(commented.area_type)
       return 'bus station'
     elsif StopAreaType.ferry_terminal_types.include?(commented.area_type)
       return 'ferry terminal'
     else
       return 'stop area'
     end
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
  
  # later, more thorough user-agent sniffing would be appropriate
  # or idealy just pick it up from, e.g., request.headers["X-device-class"], set by varnish
  # sets up @user_device and @is_mobile
  # also: might not realy be using vary headers like this, but OK for now to show intent
  def get_device_from_user_agent
    mobile_devices = ['android', 'iphone', 'ipad'] # see keyword search below
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
  
end
