class StopsController < ApplicationController
  
  def show
    @stop = Stop.find(params[:id])
  end
  
  def random
    @stop = Stop.find :first, :offset => rand(Stop.count)
    redirect_to stop_url(@stop)
  end
  
end