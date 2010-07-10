class StopSweeper < ActionController::Caching::Sweeper
  observe Stop

  def after_create(stop)
    expire_cache_for(stop)
  end
  
  def after_update(stop)
    expire_cache_for(stop)
  end
  
  def after_destroy(stop)
    expire_cache_for(stop)
  end

  private
  
  def expire_cache_for(stop)
    # expire the stop info
    expire_fragment("stop_#{stop.id}")
    # expire route info for the routes (as it includes stops)
    stop.routes.each do |route|
      expire_fragment("route_#{route.id}")
    end
    # and the info for associated stop areas (which also list stops)
    stop.stop_areas.each do |stop_area|
      expire_fragment("stop_area_#{stop_area.id}")
    end
  end
  
end