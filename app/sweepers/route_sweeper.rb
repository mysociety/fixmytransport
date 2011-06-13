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
    # also we need to explicitly specify that we want to clear the cache path with the main url
    # in it, as this code may be called from an admin controller via some proxied url
    route_path = url_for(:controller => '/locations',
                         :action => 'show_route_region',
                         :id => route.region,
                         :only_path => true)                    
    expire_fragment(main_url(route_path,{ :skip_protocol => true }))
    if route.previous_version and (route.previous_version.region_id != route.region_id)
      route_path = url_for(:controller => '/locations',
                           :action => 'show_route_region',
                           :id => route.previous_version.region,
                           :only_path => true)
      expire_fragment(main_url(route_path, { :skip_protocol => true }))
    end
  end


end