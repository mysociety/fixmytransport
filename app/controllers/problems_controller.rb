class ProblemsController < ApplicationController

  def new
    @title = t :find_location
    @problem = Problem.new()
  end
  
  def index
    @title = t :browsing_problems
    @problems = Problem.find(:all)
  end
  
  def create
    @problem = Problem.new(params[:problem])
    @location_search = LocationSearch.new_search!(session[:session_id], params)
    if @problem.save
      redirect_to location_url(@problem.location)
    else
      if !@problem.locations.empty?
        location_search.add_choice(@problem.locations)
        @title = t :multiple_locations
        render :choose_location
      else
        @title = t :find_location
        render :new
      end
    end
  end
  
  def choose_location
  end
  
  def show
    @problem = Problem.find(params[:id])
    @title = @problem.subject
  end
  
  private
  
  rescue_from ActiveRecord::RecordNotFound do
    render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
  end
  
end