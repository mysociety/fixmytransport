class StopAreasController < LocationsController
  
  def show
    @stop_area = StopArea.find(params[:id])
    @new_story = Story.new(:reporter => User.new)
    location_search.add_location(@stop_area) if location_search
  end
  
  def update
    @stop_area = StopArea.find(params[:id])
    update_location(@stop_area, params[:stop_area])
  end
  
  private
  
  def model_class
    StopArea
  end
  
end