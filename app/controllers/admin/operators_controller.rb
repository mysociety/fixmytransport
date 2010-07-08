class Admin::OperatorsController < ApplicationController
  
  layout "admin" 
  cache_sweeper :operator_sweeper, :only => [:create, :update, :destroy, :merge]
  
  def index
    conditions = []
    query_clauses = []
    if params[:query]
      query = params[:query].downcase
      query_clause = "(lower(name) like ? OR lower(short_name) like ? OR lower(code) = ?"
      2.times{ conditions << "%%#{query}%%" }
      conditions << query
      # numeric?
      if query.to_i.to_s == query
        query_clause += " OR id = ?"
        conditions << query.to_i
      end  
      query_clause += ")"
      query_clauses << query_clause
    end
    conditions = [query_clauses.join(" AND ")] + conditions
    @operators = Operator.paginate :page => params[:page], 
                                   :conditions => conditions,
                                   :order => 'name ASC'
  end
  
  def new
    @operator = Operator.new(:code => params[:code])
    if params[:code]
      @route_operators = make_route_operators(params[:code])
    else
      @route_operators = []
    end
  end
  
  def create
    @operator = Operator.new(params[:operator])
    if @operator.save
      flash[:notice] = t(:operator_created)
      redirect_to admin_url(admin_operator_path(@operator))
    else 
      if params[:operator][:code]
        @route_operators = make_route_operators(params[:operator][:code])
      else
        @route_operators = []
      end
      render :new
    end
  end
  
  def show
    @operator = Operator.find(params[:id])
    @route_operators = make_route_operators(@operator.code)
  end
   
  def update
    @operator = Operator.find(params[:id])
    if @operator.update_attributes(params[:operator])
      flash[:notice] = t(:operator_updated)
      redirect_to admin_url(admin_operator_path(@operator))
    else
      @route_operators = make_route_operators(@operator.code)
      flash[:error] = t(:operator_problem)
      render :show
    end
  end
  
  def destroy 
    @operator = Operator.find(params[:id])
    @operator.destroy
    flash[:notice] = t(:operator_destroyed)
    redirect_to admin_url(admin_operators_path)
  end

  def merge
    @operators = Operator.find(params[:operators])
    if request.post? 
      @merge_to = Operator.find(params[:merge_to])
      Operator.merge!(@merge_to, @operators)
      flash[:notice] = t(:operators_merged)
      redirect_to admin_url(admin_operator_path(@merge_to))
    end
  end

  # returns json operator info to be used in autocomplete widgets
  def autocomplete_for_name
    query = params[:term].downcase
    operators = Operator.find(:all, 
                              :conditions => ["LOWER(name) LIKE ? 
                                               OR LOWER(name) LIKE ? 
                                               OR LOWER(short_name) LIKE ?
                                               OR LOWER(short_name) LIKE ?", 
                                              "#{query}%", "%#{query}%", "#{query}%", "%#{query}%" ],
                              :limit => 20)
    operators = operators.map{ |operator| {:id => operator.id, :name => operator.name}}
    render :json => operators
  end
  
  private
  
  def make_route_operators code
    Route.find_without_operators(:operator_code => code).map{ |route| RouteOperator.new(:route => route) }
  end
  
end
