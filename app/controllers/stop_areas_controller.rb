class StopAreasController < LocationsController
  
  def show
    @stop_area = StopArea.find(params[:id])
    location_search.add_location(@stop_area) if location_search
  end
  
  private
  
  def model_class
    StopArea
  end
  
end