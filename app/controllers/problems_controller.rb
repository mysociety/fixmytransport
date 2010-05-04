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
    if @problem.save
      flash[:notice] = t :problem_location_found
      redirect_to polymorphic_url(@problem.location)
    else
      if !@problem.locations.empty?
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