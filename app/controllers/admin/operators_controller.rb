class Admin::OperatorsController < ApplicationController
  
  layout "admin" 
  
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
      @routes = Route.find_without_operators(:operator_code => params[:code])
    else
      @routes = []
    end
  end
  
  def create
    @operator = Operator.new(params[:operator])
    if @operator.save
      redirect_to admin_url(admin_operator_path(@operator))
    else 
      if params[:operator][:code]
        @routes = Route.find_without_operators(:operator_code => params[:operator][:code])
      else
        @routes = []
      end
      render :new
    end
  end
  
  def show
    @operator = Operator.find(params[:id])
    @routes = Route.find_without_operators(:operator_code => @operator.code)
  end
   
  def update
    @operator = Operator.find(params[:id])
    if @operator.update_attributes(params[:operator])
      flash[:notice] = t(:operator_updated)
      redirect_to admin_url(admin_operator_path(@operator))
    else
      @routes = Route.find_without_operators(:operator_code => @operator.code)
      flash[:error] = t(:operator_problem)
      render :show
    end
  end

end
