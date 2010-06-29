class Admin::RoutesController < ApplicationController
  
  layout "admin" 

  def show
    @route = Route.find(params[:id], :scope => params[:scope])
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
  
  def update
    @route = Route.find(params[:id], :scope => params[:scope])
    if @route.update_attributes(params[:route])
      flash[:notice] = t(:route_updated)
      redirect_to admin_url(admin_route_path(@route.region, @route))
    else
      flash[:error] = t(:route_problem)
      render :show
    end
  end

end
