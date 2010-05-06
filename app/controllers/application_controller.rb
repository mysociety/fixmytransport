# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  helper_method :location_search, :location_url, :respond_url
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  private
  
  def location_search 
    @location_search ||= LocationSearch.find_current(session_id)
  end
  
  def session_id
    # Have to load session by requesting a value in order to read session id
    # https://rails.lighthouseapp.com/projects/8994/tickets/2268-rails-23-session_optionsid-problem
    session[:foo]
    request.session_options[:id]
  end
   
  def location_url(location)
   # map any Route subclasses back to base class in order to pass to polymorphic_url
   location = location.becomes(Route) if location.is_a? Route 
   polymorphic_url(location) 
  end

  def respond_url(location, params)
   case location
   when Route
     respond_route_url(location, params)
   when Stop
     respond_stop_url(location, params)
   when StopArea
     respond_stop_area_url(location, params)
   else
     raise "Unknown location type: #{location.class}"
   end
  end
  
end
