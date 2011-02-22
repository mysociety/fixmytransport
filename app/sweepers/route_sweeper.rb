class RouteSweeper < ActionController::Caching::Sweeper
  
  observe :route
  
  def after_create(route)
    expire_cache_for(route)
  end
  
  def after_destroy(route)
    expire_cache_for(route)
  end
  
  def after_update(route)
    expire_cache_for(route)
  end
  
  private
  
  def expire_cache_for(route)
    # note the controller leading slash to prevent any namespacing of the controller
    expire_fragment(:controller => '/locations', 
                    :action => 'show_route_region', 
                    :id => route.region)
    if route.previous_version and (route.previous_version.region_id != route.region_id)
      expire_fragment(:controller => '/locations', 
                      :action => 'show_route_region', 
                      :id => route.previous_version.region)
      end
  end
  
end