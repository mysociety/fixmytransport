class StopAreaSweeper < ActionController::Caching::Sweeper
  observe StopArea

  def after_create(stop_area)
    expire_cache_for(stop_area)
  end
  
  def after_update(stop_area)
    expire_cache_for(stop_area)
  end
  
  def after_destroy(stop_area)
    expire_cache_for(stop_area)
  end

  private
  
  def expire_cache_for(stop_area)
    # expire the stop_area info
    expire_fragment("stop_area_#{stop_area.id}")
    # expire route info for the routes (as it includes stop_areas)
    stop_area.routes.each do |route|
      expire_fragment("route_#{route.id}")
    end
    # and the info for associated stops
    stop_area.stops.each do |stop|
      expire_fragment("stop_#{stop.id}")
    end
  end
  
end