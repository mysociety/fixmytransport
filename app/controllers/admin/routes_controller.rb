class Admin::RoutesController < ApplicationController
  
  layout "admin" 

  def show
    @route = Route.find(params[:id], :scope => params[:scope])
    @route_operators = make_route_operators(@route.operator_code, @route)
  end
  
  def index
    query_clauses = []
    conditions = []
    if params[:mode]
      query_clauses << "transport_mode_id = ?"
      conditions << params[:mode]
    end
    if !params[:query].blank?
      query = params[:query].downcase
      query_clause = "(lower(name) like ? OR lower(number) = ?"
      conditions << "%%#{query}%%" 
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
    @routes = Route.paginate :page => params[:page], 
                             :conditions => conditions, 
                             :order => 'number'
  end
  
  def new
    @route = Route.new
    @route_operators = []
  end
  
  def create
    @route = Route.new(params[:route])
    if @route.save
      redirect_to(admin_url(admin_route_path(@route.id)))
    else
      @route_operators = []
      render :new
    end
  end
  
  def update
    @route = Route.find(params[:id], :scope => params[:scope])
    if @route.update_attributes(params[:route])
      flash[:notice] = t(:route_updated)
      redirect_to admin_url(admin_route_path(@route.id))
    else
      @route_operators = make_route_operators(@route.operator_code, @route)
      flash[:error] = t(:route_problem)
      render :show
    end
  end
  
  private
  
  def make_route_operators code, route
    operators = Operator.find(:all, :conditions => ["code = ? AND id not in 
                                                       (SELECT operator_id
                                                        FROM route_operators 
                                                        WHERE route_id = ? )", code, route])
    operators.map{ |operator| RouteOperator.new(:operator => operator) }
  end

end
