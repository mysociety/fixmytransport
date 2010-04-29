class StopAreasController < ApplicationController
  
  def show
    @stop_area = StopArea.find(params[:id])
  end
  
  def random
    @stop_area = StopArea.find :first, :offset => rand(StopArea.count)
    redirect_to stop_area_url(@stop_area)
  end
  
end