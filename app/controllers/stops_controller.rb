class StopsController < LocationsController
  
  def show
    @stop = Stop.find(params[:id])
    @new_problem = Problem.new(:reporter => User.new)
    location_search.add_location(@stop) if location_search
  end
  
  def update
    @stop = Stop.find(params[:id])
    update_location(@stop, params[:stop])
  end
  
  private
  
  def model_class
    Stop
  end
  
end