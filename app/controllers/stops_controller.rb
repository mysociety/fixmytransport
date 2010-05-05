class StopsController < LocationsController
  
  def show
    @stop = Stop.find(params[:id])
    location_search.add_location(@stop) if location_search
  end
  
  private
  
  def model_class
    Stop
  end
  
end