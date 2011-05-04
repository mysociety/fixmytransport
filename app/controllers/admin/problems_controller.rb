class Admin::ProblemsController < Admin::AdminController

  def show 
    @problem = Problem.find(params[:id])
  end
  
  def index
    conditions = []
    @problems = Problem.paginate :page => params[:page], 
                                 :conditions => conditions, 
                                 :order => 'id desc'
  end
  
  def update
    @problem = Problem.find(params[:id])
    if @problem.update_attributes(params[:problem])
      flash[:notice] = t(:problem_updated)
      redirect_to admin_url(admin_problem_path(@problem.id))
    else
      flash[:error] = t(:problem_problem)
      render :show
    end
  end
  
end
