class RoutesController < LocationsController
  
  def show
    @route = Route.find(params[:id], :scope => params[:scope])
    @new_story = Story.new(:reporter => User.new)
    location_search.add_location(@route) if location_search
  end
  
  def update
    @route = Route.find(params[:id], :scope => params[:scope])
    update_location(@route, params[:route])
  end

  private 
  
  def model_class
    Route
  end
  
end