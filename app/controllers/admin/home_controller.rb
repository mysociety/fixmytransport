class Admin::HomeController < ApplicationController
  
  layout "admin" 
  
  def index
    @routes_without_operators = Route.find_without_operators(:limit => 20)
  end
  
end
