class StopAreaSweeper < ActionController::Caching::Sweeper

  observe :stop_area

  def after_create(stop_area)
    expire_cache_for(stop_area)
  end

  def after_destroy(stop_area)
    expire_cache_for(stop_area)
  end

  def after_update(stop_area)
    expire_cache_for(stop_area)
  end

  private

  def expire_cache_for(stop_area)
    # note the controller leading slash to prevent any namespacing of the controller
    # also we need to explicitly specify that we want to clear the cache path with the main url
    # in it, as this code may be called from an admin controller via some proxied url
      
    # expire the stop page fragments
    stop_path = url_for(:controller => '/locations', 
                         :action => 'show_stop_area', 
                         :scope => stop_area.locality,
                         :id => stop_area,
                         :only_path => true)
    stop_area_cache = main_url(stop_area_path, { :skip_protocol => true })
  
    expire_fragment("#{stop_area_cache}.action_suffix=route_list")
    expire_fragment("#{stop_area_cache}.action_suffix=map")
  end

end