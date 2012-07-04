class Admin::OperatorsController < Admin::AdminController

  before_filter :require_can_admin_organizations, :except => :autocomplete_for_name

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
    @operators = Operator.current.paginate :page => params[:page],
                                           :conditions => conditions,
                                           :order => 'name ASC'
  end

  def new
    @operator = Operator.new(:code => params[:code])
    if params[:code]
      @route_operators = make_route_operators([params[:code]])
    else
      @route_operators = []
    end
  end

  def create
    @operator = Operator.new(params[:operator])
    if @operator.save
      flash[:notice] = t('admin.operator_created')
      redirect_to admin_url(admin_operator_path(@operator))
    else
      render :new
    end
  end

  def assign_routes
    @route_operators = make_route_operators([params[:code]])
    if request.post?
      if params[:operator][:id]
        @operator = Operator.find(params[:operator][:id])
        if @operator.update_attributes(params[:operator])
          flash[:notice] = t('admin.operator_routes_added')
          redirect_to admin_url(admin_root_path)
        else
          render :assign_routes
        end
      end
    end
  end

  def show
    @operator = Operator.current.find(params[:id])
    @route_operators = make_route_operators(@operator.codes)
  end

  def update
    @operator = Operator.find(params[:id])
    if @operator.update_attributes(params[:operator])
      flash[:notice] = t('admin.operator_updated')
      add_responsibilities_notice(:operator, :route_operators_attributes, 'Route', :route_id, @operator)
      redirect_to admin_url(admin_operator_path(@operator))
    else
      @route_operators = make_route_operators(@operator.codes)
      flash.now[:error] = t('admin.operator_problem')
      render :show
    end
  end

  def destroy
    @operator = Operator.find(params[:id])
    if @operator.stop_areas.size > 0 || @operator.routes.size > 0
      flash.now[:error] = t('admin.operator_has_routes_or_stop_areas')
      @route_operators = make_route_operators(@operator.codes)
      render :show
    else
      @operator.destroy
      flash[:notice] = t('admin.operator_destroyed')
      redirect_to admin_url(admin_operators_path)
    end
  end

  def merge
    if params[:operators].blank?
      redirect_to admin_url(admin_operators_path)
      return
    end
    @operators = Operator.find(params[:operators])
    if request.post?
      @merge_to = Operator.find(params[:merge_to])
      Operator.merge!(@merge_to, @operators)
      flash[:notice] = t('admin.operators_merged')
      redirect_to admin_url(admin_operator_path(@merge_to))
    end
  end

  # returns json operator info to be used in autocomplete widgets
  def autocomplete_for_name
    id_param = params[:id_param] == 'persistent_id' ? :persistent_id : :id
    query = params[:term].downcase
    operators = Operator.find(:all,
                              :conditions => ["LOWER(name) LIKE ?
                                               OR LOWER(name) LIKE ?
                                               OR LOWER(short_name) LIKE ?
                                               OR LOWER(short_name) LIKE ?",
                                              "#{query}%", "%#{query}%", "#{query}%", "%#{query}%" ],
                              :limit => 20)
    operators = operators.map{ |operator| {:id => operator.send(id_param), :name => operator.name}}
    render :json => operators
  end

  private

  def make_route_operators codes
    return [] if codes.empty?
    Route.find_current_without_operators(:operator_codes => codes).map{ |route| RouteOperator.new(:route => route) }
  end

end
