class RoutesController < LocationsController
  
  def show
    @route = Route.full_find(params[:id], params[:scope])
    @new_story = Story.new(:reporter => User.new)
    location_search.add_location(@route) if location_search
  end
  
  def update
    @route = Route.full_find(params[:id], params[:scope])
    # the hash is dependent on the sti subclass - we could recast using
    # ActiveRecord::Base.becomes but it is quite slow
    route_hash_key = @route.class.to_s.underscore.to_sym
    update_location(@route, params[route_hash_key])
  end

  private 
  
  def model_class
    Route
  end
  
end