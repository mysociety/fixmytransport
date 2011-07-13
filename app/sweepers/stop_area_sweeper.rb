class StopAreaSweeper < LocationSweeper

  observe :stop_area

  def after_create(stop_area)
    expire_stop_area_cache_for(stop_area)
  end

  def after_destroy(stop_area)
    expire_stop_area_cache_for(stop_area)
  end

  def after_update(stop_area)
    expire_stop_area_cache_for(stop_area)
  end

  def expire_stop_area_cache_for(stop_area)
    expire_stop_area_fragments(stop_area)
    stop_area.routes.each do |route|
      expire_route_fragments(route)
    end
  end

end