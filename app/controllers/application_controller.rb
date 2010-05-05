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
    @location_search ||= LocationSearch.find_current(session[:session_id])
  end
   
  def location_url(location)
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
