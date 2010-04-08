class ProblemsController < ApplicationController

  def new
    @title = t :submit_problem
    @problem = Problem.new
    @problem.build_reporter
  end
  
  def index
    @title = t :browsing_problems
    @problems = Problem.find(:all)
  end
  
  def create
    @problem = Problem.new(params[:problem])
    if @problem.save
      flash[:notice] = t :problem_created
      redirect_to problem_url(@problem)
    else
      @title = t :submit_problem
      render :new
    end
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