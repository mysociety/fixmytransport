class RoutesController < LocationsController
  
  def show
    @route = Route.find(params[:id])
    location_search.add_location(@route) if location_search
  end

  private 
  
  def model_class
    Route
  end
  
end