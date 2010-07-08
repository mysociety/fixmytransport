class Admin::RoutesController < ApplicationController
  
  layout "admin" 
  cache_sweeper :route_sweeper, :only => [:create, :update, :destroy]

  def show
    @route = Route.find(params[:id])
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
    @route = Route.new(:loaded => true)
    @route_operators = []
  end
  
  def create
    @route = Route.new(params[:route])
    if @route.save
      flash[:notice] = t(:route_created)
      redirect_to(admin_url(admin_route_path(@route.id)))
    else
      @route_operators = []
      render :new
    end
  end
  
  def update
    @route = Route.find(params[:id])
    if @route.update_attributes(params[:route])
      flash[:notice] = t(:route_updated)
      redirect_to admin_url(admin_route_path(@route.id))
    else
      @route_operators = make_route_operators(@route.operator_code, @route)
      flash[:error] = t(:route_problem)
      render :show
    end
  end
  
  def destroy 
    @route = Route.find(params[:id])
    if @route.stories.size > 0
      flash[:error] = t(:route_has_stories)
      @route_operators = make_route_operators(@route.operator_code, @route)
      render :show
    else
      @route.destroy
      flash[:notice] = t(:route_destroyed)
      redirect_to admin_url(admin_routes_path)
    end
  end
  
  private
  
  def make_route_operators code, route
    operators = Operator.find(:all, :conditions => ["code = ? AND id not in 
                                                       (SELECT operator_id
                                                        FROM route_operators 
                                                        WHERE route_id = ? )", code, route.id])
    operators.map{ |operator| RouteOperator.new(:operator => operator) }
  end

end
