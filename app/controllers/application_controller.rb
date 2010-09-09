# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # send exception mails
  include ExceptionNotification::Notifiable
  include MySociety::UrlMapper
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
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

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = t(:must_be_logged_in)
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = t(:must_be_logged_out)
      redirect_to root_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
  
  # For administration interface, return display name of authenticated user
  def admin_http_auth_user
    if request.env["REMOTE_USER"]
      return request.env["REMOTE_USER"]
    else
      return "*unknown*";
    end
  end
  
  def user_for_paper_trail
    admin_http_auth_user
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
  
  def process_map_params
    @zoom = params[:zoom].to_i if params[:zoom] && (MIN_ZOOM_LEVEL <= params[:zoom].to_i && params[:zoom].to_i <= MAX_VISIBLE_ZOOM)
    @lon = params[:lon].to_f if params[:lon] 
    @lat = params[:lat].to_f if params[:lat]
  end
  
  # set the lat, lon and zoom based on the locations being shown, and find other locations
  # within the bounding box
  def map_params_from_location(locations, find_other_locations=false)
    @find_other_locations = find_other_locations
    # check for an array of routes
    if locations.first.is_a?(Route)
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
      @zoom = Map::zoom_to_coords(lons.min, lons.max, lats.min, lats.max)
    end
    if find_other_locations
      @other_locations = Map.other_locations(@lat, @lon, @zoom)
    else
      @other_locations = []
    end
  end
  
end
