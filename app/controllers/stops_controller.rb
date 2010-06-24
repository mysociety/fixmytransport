class StopsController < LocationsController
  
  def show
    @stop = Stop.full_find(params[:id], params[:scope])
    @new_story = Story.new(:reporter => User.new)
    if location_search
      location_search.add_location(@stop) 
      @new_story.transport_mode_id = location_search.transport_mode_id 
    end
  end
  
  def update
    @stop = Stop.full_find(params[:id], params[:scope])
    update_location(@stop, params[:stop])
  end
  
  private
  
  def model_class
    Stop
  end
  
end