class RoutesController < ApplicationController
  
  def show
    @route = Route.find(params[:id])
  end
  
  def random
    @route = Route.find :first, :offset => rand(Route.count)
    redirect_to route_url(@route)
  end
  
end