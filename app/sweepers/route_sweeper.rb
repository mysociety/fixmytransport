class RouteSweeper < LocationSweeper

  observe :route, :route_segment

  def after_create(route_or_segment)
    expire_route_or_segment(route_or_segment)
  end

  def after_destroy(route_or_segment)
    expire_route_or_segment(route_or_segment)
  end

  def after_update(route_or_segment)
    expire_route_or_segment(route_or_segment)
  end

  private

  
  def expire_route_or_segment(route_or_segment)
    if route_or_segment.is_a?(Route)
      expire_route_cache_for(route_or_segment)
    else 
      expire_route_segment_cache_for(route_or_segment)
    end
  end
  
  def expire_route_segment_cache_for(route_segment)
    if route_segment.from_stop
      expire_stop_fragments(route_segment.from_stop)
    end
    if route_segment.to_stop
      expire_stop_fragments(route_segment.to_stop)
    end
    if route_segment.from_stop_area
      expire_stop_area_fragments(route_segment.from_stop_area)
    end
    if route_segment.to_stop_area
      expire_stop_area_fragments(route_segment.to_stop_area)
    end
  end

  def expire_route_cache_for(route)
    # note the controller leading slash to prevent any namespacing of the controller
    # also we need to explicitly specify that we want to clear the cache path with the main url
    # in it, as this code may be called from an admin controller via some proxied url
    
    # expire the route region page fragment
    route_region_path = url_for(:controller => '/locations',
                         :action => 'show_route_region',
                         :id => route.region,
                         :only_path => true)                    
    expire_fragment(main_url(route_region_path,{ :skip_protocol => true }))
    if route.previous_version and (route.previous_version.region_id != route.region_id)
      route_region_path = url_for(:controller => '/locations',
                           :action => 'show_route_region',
                           :id => route.previous_version.region,
                           :only_path => true)
      expire_fragment(main_url(route_region_path, { :skip_protocol => true }))
    end
      
    expire_route_fragments(route)
    # expire the fragments of any associated stops and stop areas
    route.all_locations.each do |location|
      if location.is_a?(Stop)
        expire_stop_fragments(location)
      end
      if location.is_a?(StopArea)
        expire_stop_area_fragments(location)
      end
    end
  end
  
end