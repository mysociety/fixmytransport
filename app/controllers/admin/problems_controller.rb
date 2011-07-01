class Admin::ProblemsController < Admin::AdminController

  def show 
    @problem = Problem.find(params[:id])
  end
  
  def index
    conditions = []
    query_clauses = []
    if params[:query]
      query = params[:query].downcase
      query_clause = "(lower(subject) like ?"
      conditions << "%%#{query}%%" 
      # numeric?
      if query.to_i.to_s == query
        query_clause += " OR id = ?"
        conditions << query.to_i
      end  
      query_clause += ")"
      query_clauses << query_clause
    end
    conditions = [query_clauses.join(" AND ")] + conditions
    @problems = Problem.paginate :page => params[:page], 
                                 :conditions => conditions, 
                                 :order => 'id desc'
  end
  
  def update
    @problem = Problem.find(params[:id])
    @problem.status_code = params[:problem][:status_code]
    if @problem.update_attributes(params[:problem])
      flash[:notice] = t('admin.problem_updated')
      redirect_to admin_url(admin_problem_path(@problem.id))
    else
      flash[:error] = t('admin.problem_problem')
      render :show
    end
  end
  
end
