class Admin::RoutesController < Admin::AdminController
  
  cache_sweeper :route_sweeper
  helper_method :sort_column, :sort_direction

  def show
    @route = Route.find(params[:id], :include => [ {:journey_patterns => 
                                                      {:route_segments  => [:from_stop, :to_stop]}}])
    @route_operators = make_route_operators(@route)
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
      query_clause = "(lower(routes.name) like ? OR lower(number) = ?"
      conditions << "%%#{query}%%" 
      conditions << query
      # numeric?
      if query.to_i.to_s == query
        query_clause += " OR routes.id = ?"
        conditions << query.to_i
      end
      query_clause += ")"
      query_clauses << query_clause
    end
    conditions = [query_clauses.join(" AND ")] + conditions
    @routes = Route.paginate :select => "distinct routes.*",
                             :page => params[:page], 
                             :conditions => conditions, 
                             :include => :region,
                             :order => "#{sort_column} #{sort_direction}"
  end
  
  def new
    @route = Route.new(:loaded => true)
    @route_operators = []
  end
  
  def create
    @route_operators = []
    if params[:route][:transport_mode_id].blank?
      @route = Route.new(params[:route])
      render :new
      return
    end
    transport_mode = TransportMode.find(params[:route][:transport_mode_id])
    route_type = transport_mode.route_type.constantize
    @route = route_type.new(params[:route])
    if @route.save
      flash[:notice] = t(:route_created)
      redirect_to(admin_url(admin_route_path(@route.id)))
    else
      render :new
    end
  end
  
  def update
    # The inclusion of journey_patterns and route_segments is required for changes to be saved correctly - 
    # several callbacks on route use the associations and they need to all be acting on the same
    # model instances, otherwise changes don't get saved.
    @route = Route.find(params[:id], :include => {:journey_patterns => :route_segments})
    if @route.update_attributes(params[:route])
      flash[:notice] = t(:route_updated)
      redirect_to admin_url(admin_route_path(@route.id))
    else
      @route_operators = make_route_operators(@route)
      flash[:error] = t(:route_problem)
      render :show
    end
  end
  
  def destroy 
    @route = Route.find(params[:id])
    if @route.campaigns.size > 0
      flash[:error] = t(:route_has_campaigns)
      @route_operators = make_route_operators(@route)
      render :show
    else
      @route.destroy
      flash[:notice] = t(:route_destroyed)
      redirect_to admin_url(admin_routes_path)
    end
  end
  
  def compare
    if request.post?
      @merge_candidate = MergeCandidate.find(params[:id])
      if params[:is_same] == 'yes'
        @merge_candidate.update_attribute('is_same', true)
      end
      if params[:is_same] == 'no'
        @merge_candidate.update_attribute('is_same', false)
      end
      redirect_to admin_url(compare_admin_routes_path)
    end
    @merge_candidate = MergeCandidate.find(:first, :conditions => 'is_same is null', :order => 'random()')
    route_ids = @merge_candidate.regional_route_ids.split("|")
  
    regional_routes = Route.find(:all, :conditions => ['id in (?)', route_ids],
                                       :include => {:journey_patterns => {:route_segments => [:from_stop, :to_stop] }})
    @routes = [@merge_candidate.national_route] + regional_routes
  end
  
  def merge
    if params[:routes].blank?
      redirect_to admin_url(admin_routes_path)
      return
    end
    @routes = Route.find(params[:routes])
    if request.post? 
      @merge_to = Route.find(params[:merge_to])
      Route.merge!(@merge_to, @routes)
      flash[:notice] = t(:routes_merged)
      redirect_to admin_url(admin_route_path(@merge_to.id))
    end
  end
  
  private

  
  def make_route_operators route
    codes = route.route_source_admin_areas.map{ |route_source_admin_area| route_source_admin_area.operator_code }
    operators = Operator.find(:all, :conditions => ["operator_codes.code in (?) 
                                                     AND operators.id not in 
                                                       (SELECT operator_id
                                                        FROM route_operators 
                                                        WHERE route_id = ? )", codes, route.id],
                                    :include => :operator_codes)
    operators.map{ |operator| RouteOperator.new(:operator => operator) }
  end
  

  def sort_column
    columns = Route.column_names + ["regions.name"]
    columns.include?(params[:sort]) ? params[:sort] : "number"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

end