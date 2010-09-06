class OperatorsController < ApplicationController
  
  def show
    @operator = Operator.find(params[:id])
  end

end