class StopSweeper < LocationSweeper

  observe :stop

  def after_create(stop)
    expire_stop_cache_for(stop)
  end

  def after_destroy(stop)
    expire_stop_cache_for(stop)
  end

  def after_update(stop)
    expire_stop_cache_for(stop)
  end
  
  def expire_stop_cache_for(stop)
    expire_stop_fragments(stop)
    stop.routes.each do |route|
      expire_route_fragments(route)
    end
  end

end