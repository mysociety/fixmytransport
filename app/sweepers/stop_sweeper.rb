class StopSweeper < ActionController::Caching::Sweeper

  observe :stop

  def after_create(stop)
    expire_cache_for(stop)
  end

  def after_destroy(stop)
    expire_cache_for(stop)
  end

  def after_update(stop)
    expire_cache_for(stop)
  end

  private

  def expire_cache_for(stop)
    # note the controller leading slash to prevent any namespacing of the controller
    # also we need to explicitly specify that we want to clear the cache path with the main url
    # in it, as this code may be called from an admin controller via some proxied url
      
    # expire the stop page fragments
    stop_path = url_for(:controller => '/locations', 
                         :action => 'show_stop', 
                         :scope => stop.locality,
                         :id => stop,
                         :only_path => true)
    stop_cache = main_url(stop_path, { :skip_protocol => true })
  
    expire_fragment("#{stop_cache}.action_suffix=route_list")
    expire_fragment("#{stop_cache}.action_suffix=map")
  end

end