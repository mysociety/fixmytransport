class OperatorsController < ApplicationController
  
  def show
    @operator = Operator.find(params[:id],
                              :include => [ { :route_operators => { :route => :region } }, 
                                            { :stop_areas => :locality } ])
  end

end