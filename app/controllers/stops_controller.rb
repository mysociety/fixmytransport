class StopsController < LocationsController
  
  def show
    @stop = Stop.full_find(params[:id], params[:scope])
    @new_story = Story.new(:reporter => User.new)
    location_search.add_location(@stop) if location_search
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