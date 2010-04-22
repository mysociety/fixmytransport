class RoutesController < ApplicationController
  
  def show
    @route = Route.find(params[:id])
  end
  
end