class StopsController < ApplicationController
  
  def show
    @stop = Stop.find(params[:id])
  end
  
end