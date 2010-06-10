class RoutesController < LocationsController
  
  def show
    @route = Route.find(params[:id])
    @new_Story = Story.new(:reporter => User.new)
    location_search.add_location(@route) if location_search
  end
  
  def update
    @route = Route.find(params[:id])
    update_location(@route, params[:route])
  end

  private 
  
  def model_class
    Route
  end
  
end