class LocationSweeper < ActionController::Caching::Sweeper
  
  include ApplicationHelper
  
  private

  def expire_stop_fragments(stop)     
    # expire the stop page fragments
    stop_cache = stop_cache_path(stop)
    expire_fragment("#{stop_cache}.action_suffix=route_list")
    expire_fragment("#{stop_cache}.action_suffix=map")
  end
  
  def expire_stop_area_fragments(stop_area)
    stop_area_path = location_path(stop_area)
    stop_area_cache = main_url(stop_area_path, { :skip_protocol => true })
    expire_fragment("#{stop_area_cache}.action_suffix=route_list")
    expire_fragment("#{stop_area_cache}.action_suffix=map")
  end
  
  def expire_route_fragments(route)
    # expire the route page fragments
    route_path = url_for(:controller => '/locations', 
                         :action => 'show_route', 
                         :scope => route.region,
                         :id => route,
                         :only_path => true)
    route_cache = main_url(route_path, { :skip_protocol => true })
  
    expire_fragment("#{route_cache}.action_suffix=stop_list")
    expire_fragment("#{route_cache}.action_suffix=map")
  end

end