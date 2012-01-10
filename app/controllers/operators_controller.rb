class OperatorsController < ApplicationController
  
  skip_before_filter :make_cachable
  before_filter :long_cache
  before_filter :find_operator, :setup_shared_title
  
  def show
    @title = @operator.name 
    @current_tab = :issues
    setup_paginated_issues
    @banner_text = t('route_operators.show.issues_concerning', 
                      :operator => "<a href='#{operator_url(@operator)}'>#{@operator.name}</a>", 
                      :count => @issue_count)
    @station_count = find_station_count
    @route_count = find_route_count
  end
  
  # routes, issues and stations are all presented as tabs on the operator page
  # They're implemented as separate pages because managing three different paginations
  # on the same page results in some ugly URLs (three page params) as well as making
  # AJAX calls on the pagination links. Simpler to implement it as separate pages.

  # "issues" differs from "show" only in the title
  def issues
    show
    @title = t('route_operators.issues.title', :operator => @operator.name) 
    render :show
  end

  def routes 
    @title = t('route_operators.routes.title', :operator => @operator.name) 
    @current_tab = :routes
    setup_paginated_routes
    @banner_text = t('route_operators.show.operates_routes', 
                      :operator => "<a href='#{operator_url(@operator)}'>#{@operator.name}</a>", 
                      :count => @route_count)
    @station_count = find_station_count
    @issue_count = find_issue_count
    render :show
  end

  def stations 
    @current_tab = :stations
    setup_paginated_stations
    @title = t('route_operators.stations.title', :operator => @operator.name) 
    @banner_text = t('route_operators.show.is_responsible_for_stations', 
                      :operator => "<a href='#{operator_url(@operator)}'>#{@operator.name}</a>", 
                      :count => @station_count)
    @route_count = find_route_count
    @issue_count = find_issue_count
    render :show
  end

  private 

  def find_operator
    @operator = Operator.find(params[:id])
  end
  
  def setup_shared_title
    @links_per_page = 20
    @title = @operator.name
    linked_operator_name = self.action_name == 'show' ? @operator.name : "<a href='#{operator_path(@operator)}'>#{@operator.name}</a>"
    if @operator.transport_mode
      @transport_mode_and_link = t('route_operators.show.is_an_operator_with_transport_mode', 
                                    :operator => linked_operator_name,
                                    :transport_mode => @operator.transport_mode.name.downcase) 
    elsif
      @transport_mode_and_link = t('route_operators.show.is_an_operator', :operator => linked_operator_name) 
    end
  end

  def find_issue_count
    problem_count = Problem.visible.count(:conditions => ["id in (SELECT problem_id 
                                                           FROM responsibilities 
                                                           WHERE organization_type = 'Operator'
                                                           AND organization_id = #{@operator.id})"])                                             
    campaign_count = Campaign.visible.count(:conditions => ["id in (SELECT campaign_id FROM problems
                                                            WHERE problems.id in (
                                                            SELECT problem_id 
                                                            FROM responsibilities 
                                                            WHERE organization_type = 'Operator'
                                                            AND organization_id = #{@operator.id}))"])
    return problem_count + campaign_count
  end
  
  def setup_paginated_issues
    issues_per_page = 10  
    @issues = WillPaginate::Collection.create((params[:page] or 1), issues_per_page) do |pager|
      issues = Problem.find_recent_issues(pager.per_page, {:offset => pager.offset, :single_operator => @operator})
      pager.replace(issues)
      if pager.total_entries
        @issue_count = pager.total_entries
      else
        @issue_count = find_issue_count
        pager.total_entries = @issue_count
      end    
    end
  end
  
  def find_station_count
    return Operator.connection.select_value("SELECT count(DISTINCT stop_areas.id) 
                                                         AS count_stop_areas_id 
                                                         FROM stop_areas
                                                         INNER JOIN stop_area_operators
                                                         ON stop_areas.id = stop_area_operators.stop_area_id 
                                                         WHERE (stop_area_operators.operator_id = #{@operator.id})").to_i
  end
  
  def setup_paginated_stations
    @stations = WillPaginate::Collection.create((params[:page] or 1), @links_per_page) do |pager|
      stations = StopArea.find(:all, :conditions => ["id in (SELECT stop_area_id 
                                                              FROM stop_area_operators
                                                              WHERE operator_id = #{@operator.id})"],
                                      :include => :slug,
                                      :order => 'name asc',
                                      :limit => @links_per_page,
                                      :offset => pager.offset)   
      pager.replace(stations)
      if pager.total_entries
        @station_count = pager.total_entries
      else
        @station_count = find_station_count
        pager.total_entries = @station_count
      end
    end    
  end
  
  def find_route_count
    return Operator.connection.select_value("SELECT count(DISTINCT routes.id) AS count_routes_id 
                                                     FROM routes 
                                                     INNER JOIN route_operators 
                                                     ON routes.id = route_operators.route_id 
                                                     WHERE (route_operators.operator_id = #{@operator.id})").to_i
  end
  
  def setup_paginated_routes
    @routes = WillPaginate::Collection.create((params[:page] or 1), @links_per_page) do |pager|
      routes = Route.find(:all, :conditions => ["id in (SELECT route_id
                                                                FROM route_operators
                                                                WHERE operator_id = #{@operator.id})"],
                                        :include => :slug,
                                        :order => 'cached_description asc',
                                        :limit => @links_per_page,
                                        :offset => pager.offset)   
      pager.replace(routes)
      if pager.total_entries
        @route_count = pager.total_entries
      else
        @route_count = find_route_count
        pager.total_entries = @route_count
      end
    end    
  end
  
end