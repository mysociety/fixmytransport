class RoutesController < LocationsController
  
  def show
    @route = Route.full_find(params[:id], params[:scope])
    @new_story = Story.new(:reporter => User.new)
    @new_story.transport_mode_id = @route.transport_mode_id
    location_search.add_location(@route) if location_search
    @title = @route.name
    respond_to do |format|
      format.html
      format.atom do  
        @stories = @route.stories.confirmed
        render :template => 'shared/stories.atom.builder', :layout => false 
      end
    end
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