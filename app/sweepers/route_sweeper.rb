class RouteSweeper < ActionController::Caching::Sweeper
  observe Route, RouteSegment

  def after_create(record)
    expire_cache_for(record)
  end
  
  def after_update(record)
    expire_cache_for(record)
  end
  
  def after_destroy(record)
    expire_cache_for(record)
  end

  private
  
  def expire_cache_for(record)
    if record.is_a? Route
      # expire the route info
      expire_fragment("route_#{record.id}")
      # expire stop info for the route stops (as it includes route)
      # note that stops is memoized so still returning the pre-update stops
      record.stops.each do |stop|
        expire_fragment("stop_#{stop.id}")
        # and the info for associated stop areas (which also lists routes)
        stop.stop_areas.each do |stop_area|
          expire_fragment("stop_area_#{stop_area.id}")
        end
      end
    end
    if record.is_a? RouteSegment
      # if a segment is removed from or added to a route, this should update the stops
      expire_fragment("stop_#{record.from_stop.id}")
      expire_fragment("stop_#{record.to_stop.id}")
    end
  end
  
end