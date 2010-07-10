class OperatorSweeper < ActionController::Caching::Sweeper
  observe Operator, RouteOperator

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
    if record.is_a? Operator
      record.routes.each do |route|
        # expire route info for the routes (as it includes operators)
        expire_fragment("route_#{route.id}")
      end
    end
    if record.is_a? RouteOperator
      expire_fragment("route_#{record.route_id}")
    end
  end
  
end