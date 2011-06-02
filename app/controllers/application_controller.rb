# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # send exception mails
  include ExceptionNotification::Notifiable
  include MySociety::UrlMapper
  helper :all # include all helpers, all the time
  protect_from_forgery if :current_user # See ActionController::RequestForgeryProtection for details
  skip_before_filter :verify_authenticity_token, :unless => :current_user

  helper_method :location_search,
                :main_url,
                :admin_url,
                :current_user_session,
                :current_user
  url_mapper # See MySociety::UrlMapper
  # Scrub sensitive parameters from the log
  filter_parameter_logging :password, :password_confirmation
  before_filter :initialize_feedback

  private

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
      access_message_key = :access_this_page
      flash[:notice] = t(:must_be_logged_in, :requested_action => t(access_message_key))
      redirect_to new_user_session_url
      return false
    end
  end

  # filter method for requiring no logged-in user
  def require_no_user
    if current_user
      store_location
      flash[:notice] = t(:must_be_logged_out)
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
    if params[param].to_i.to_s == params[param]
      @campaign = Campaign.find(params[param])
    else
      @campaign = Campaign.find_by_subdomain(params[param])
    end
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
    @name = t(:a_fixmytransport_boffin)
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
    if current_user
      store_location
      render :template => "shared/wrong_user"
      return false
    end
    flash[:notice] = t(:login_to, :user => @name, :requested_action => t(@access_message))
    store_location
    redirect_to login_url
    return false
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def access_message_key
    "#{controller_name}_#{@action_name}_access_message".to_sym
  end

  # For administration interface, return display name of authenticated user.
  # Otherwise, currently logged in user
  def user_for_edits
    if request.env["REMOTE_USER"]
      return request.env["REMOTE_USER"]
    elsif current_user
      return current_user
    else
      return "*unknown*";
    end
  end

  def user_for_paper_trail
    user_for_edits
  end

  def initialize_feedback
    @feedback = Feedback.new
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
    if post_login_action_data = get_action_data(params)
      id = post_login_action_data[:id]
      case post_login_action_data[:action]
      when :join_campaign
        campaign = Campaign.find(id)
        campaign.add_supporter(user, confirmed=false)
      when :add_comment
      when :create_problem
      end
    end
  end
  
  def post_login_action_string
    if post_login_action_data = get_action_data(session)
      case post_login_action_data[:action]
      when :join_campaign
        return t(:you_will_not_be_a_supporter)
      when :add_comment
        return t(:your_comment_will_not_be_added)
      when :create_problem
        return t(:your_problem_will_not_be_created)
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
        commented = commented_type.titleize.constantize.find(id)
        commented.add_comment(current_user, 
                             post_login_action_data[:text],
                             confirmed=true)
        flash[:notice] = "Thanks for your comment"
      when :create_problem
        problem = Problem.new(:subject => post_login_action_data[:subject], 
                              :description => post_login_action_data[:description],
                              :location_id => post_login_action_data[:location_id], 
                              :location_type => post_login_action_data[:location_type],
                              :category => post_login_action_data[:category],
                              :operator_id => post_login_action_data[:operator_id],
                              :passenger_transport_executive_id => post_login_action_data[:passenger_transport_executive_id], 
                              :council_info => post_login_action_data[:council_info])
        problem.status = :new
        problem.reporter = current_user
        problem.reporter_name = current_user.name
        problem.save!
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

  def process_map_params
    @zoom = params[:zoom].to_i if params[:zoom] && (MIN_ZOOM_LEVEL <= params[:zoom].to_i && params[:zoom].to_i <= MAX_VISIBLE_ZOOM)
    @lon = params[:lon].to_f if params[:lon]
    @lat = params[:lat].to_f if params[:lat]
  end

  # set the lat, lon and zoom based on the locations being shown, and find other locations
  # within the bounding box
  def map_params_from_location(locations, find_other_locations=false, height=MAP_HEIGHT, width=MAP_WIDTH)
    @find_other_locations = find_other_locations
    # check for an array of routes
    if locations.first.is_a?(Route) && !locations.first.show_as_point
      locations = locations.map{ |location| location.points }.flatten
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
      @other_locations = Map.other_locations(@lat, @lon, @zoom, height, width)
    else
      @other_locations = []
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
          flash[:notice] = 'Thanks for your comment!'
          redirect_to @template.commented_url(@comment.commented)
        end
        format.json do
          index = params[:last_thread_index].to_i + 1
          comment_html = render_to_string :partial => "shared/comment", 
                                          :locals => { :comment => @comment, 
                                                       :index => index }
          @json = { :success => true,
                    :html => "<li>#{comment_html}</li>" }
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
      commented_type = @comment.commented_type.downcase
      comment_data = { :action => :add_comment,
                       :id => @comment.commented_id,
                       :commented_type => commented_type,
                       :text => @comment.text,
                       :redirect => @template.commented_url(@comment.commented),
                       :notice => "Please login or signup to add your comment to this #{commented_type}" }
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

end
