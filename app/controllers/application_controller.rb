# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # send exception mails
  include ExceptionNotification::Notifiable
  include MySociety::UrlMapper
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  helper_method :location_search, 
                :location_url, 
                :location_path, 
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
  
  def location_path(location)
    if location.is_a? Stop
      return stop_path(location.locality, location)
    elsif location.is_a? StopArea
      if StopAreaType.station_types.include?(location.area_type)
         return station_path(location.locality, location, attributes)
       elsif StopAreaType.ferry_terminal_types.include?(location.area_type)
         return ferry_terminal_path(location.locality, location, attributes)
       else
         return stop_area_path(location.locality, location)
      end
    elsif location.is_a? Route
      return route_path(location.region, location)
    end
    raise "Unknown location type: #{location.class}"
  end
  
  def location_url(location, attributes={})
   if location.is_a? Stop
     return stop_url(location.locality, location, attributes)
   elsif location.is_a? StopArea
     if StopAreaType.station_types.include?(location.area_type)
       return station_url(location.locality, location, attributes)
     elsif StopAreaType.ferry_terminal_types.include?(location.area_type)
       return ferry_terminal_url(location.locality, location, attributes)
     else
       return stop_area_url(location.locality, location, attributes)
     end
   elsif location.is_a? Route
     return route_url(location.region, location, attributes)
   end
   raise "Unknown location type: #{location.class}"
  end
  
end
