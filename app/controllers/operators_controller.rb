class OperatorsController < ApplicationController
  
  skip_before_filter :make_cachable
  before_filter :long_cache
  before_filter :find_operator, :except => [:index]
  before_filter :setup_shared_title, :except => [:index]
  before_filter :setup_issues_feed, :only => [:show, :issues, :routes]
  
  def index
    @operator_list_threshold = 20
    @operator_initial_chars = []
    @operator_count = 0
    operators = []
    conditions = []
    if params[:query]=~ /[[:alnum:]]{1}/ # at least one alphanum... but maybe choke it? 
      @search_query = params[:query].downcase.gsub(/\s+/, " ").strip  # multiple spaces most likely to be in error 
      conditions << "(lower(name) like ? OR lower(short_name) like ?)"
      2.times{ conditions << "%%#{@search_query}%%" }
      operators_by_letter = MySociety::Util.by_letter(Operator.find(:all, :conditions => conditions), :upcase){|o| o.name }
      operators_by_letter.each_value {|ops| @operator_count  += ops.size }
    else
      operators_by_letter = Operator.all_by_letter # memoized
      @operator_count = Operator.count(:all)
    end
    if @operator_count > @operator_list_threshold
      if ! (params[:initial_char].blank? || params[:initial_char].empty?)
        requested_initial = params[:initial_char][0].chr.upcase
        if operators_by_letter.has_key?(requested_initial)
          @initial_char = requested_initial
        end # else maybe should redirect to letterless index
      end
      @operator_initial_chars = operators_by_letter.keys.sort
      if @initial_char.blank?
        @initial_char = @operator_initial_chars.first # if no explicit initial letter (tab), display the first one
      end
      operators = operators_by_letter[@initial_char]
    else
      operators_by_letter.each_value {|ops| operators.concat(ops) }
    end
    operators = operators.sort!{|o1, o2| o1.name.downcase <=> o2.name.downcase}
    @operators = WillPaginate::Collection.create((params[:page] or 1), 20 ) do |pager|
      pager.replace(operators[pager.offset, pager.per_page])      
      if ! pager.total_entries
        pager.total_entries = operators.size
      end    
    end
  end

  def setup_issues_feed
    @issues_feed_params = params.clone
    @issues_feed_params[:format] = 'atom'
  end

  def show
    @title = @operator.name 
    @current_tab = :issues
    setup_paginated_issues
    @banner_text = t('route_operators.show.issues_concerning', 
                      :operator => @operator.name, 
                      :count => @issue_count)
    @station_count = find_station_count
    @route_count = find_route_count
    @station_type_descriptions = setup_station_type_descriptions
  end
  
  # Routes, issues and stations are all presented as tabs on the operator page
  # They're implemented as separate pages because managing three different paginations
  # on the same http page results in some ugly URLs (three page params) as well as making
  # AJAX calls on the pagination links. Simpler to implement it as separate pages.
  # Currently, "issues" differs from "show" only in the title.

  # Note: we don't show tabs for routes or stations if there are none. 
  #       The issues tab is always shown, even if there are none.
  #       This is why the view's will_paginate has {:action => issues } on it, 
  #       since it's possible for the repagination links to be going to a different 
  #       action from the one that is actually showing the page.

  # Also: routes returned are based on *responsible* operator, so if a problem was 
  #       reported to another organisation (e.g., a PTE) then that route won't show here.
  
  def issues
    respond_to do |format|
      format.html do
        show
        @title = t('route_operators.issues.title', :operator => @operator.name)
        render :show
      end
      format.atom do
        @title = t('route_operators.issues.feed_title', :operator => @operator.name)
        @issues = Problem.find_recent_issues false, :single_operator => @operator
        render :template => 'shared/issues.atom.builder', :layout => false
      end
    end
  end

  def routes 
    @title = t('route_operators.routes.title', :operator => @operator.name) 
    @current_tab = :routes
    setup_paginated_routes
    if @route_count == 0
      @current_tab = :issues
      setup_paginated_issues
    else
      @issue_count = find_issue_count
    end
    @banner_text = t('route_operators.show.operates_routes', 
                      :operator => @operator.name, 
                      :count => @route_count)
    @station_count = find_station_count
    @station_type_descriptions = setup_station_type_descriptions
    render :show
  end

  def stations 
    @current_tab = :stations
    setup_paginated_stations
    if @station_count == 0
      @current_tab = :issues
      setup_paginated_issues
    else
      @issue_count = find_issue_count
    end
    @route_count = find_route_count
    @station_type_descriptions = setup_station_type_descriptions
    # yes it's a wee bit horrible: plural handling outside the translation files
    @banner_text = t('route_operators.show.is_responsible_for_stations', 
                      :operator => @operator.name, 
                      :station_type => @station_count == 1 ? @station_type_descriptions[:singular] : @station_type_descriptions[:plural],
                      :count => @station_count)
    @title = t('route_operators.stations.title', :operator => @operator.name, :station_type => @station_type_descriptions[:plural]) 
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
  
  # determine whether this operator has stations, bus stations, or ferry terminals: 
  # call setup_station_type_description after everything else: we can avoid hitting the database again
  # if we've already got stations, or if we know there aren't any to find
  
  def setup_station_type_descriptions
    if @station_count > 0
      if ! @stations.nil? && @stations.size > 0
        sample_station = @stations.first
      else
        sample_station = StopArea.first(:conditions => ["id in (SELECT stop_area_id 
                                                                FROM stop_area_operators
                                                                WHERE operator_id = #{@operator.id})"],
                                        :order => 'name asc') # order cautiously ensures same result as "stations" tab
      end
      descriptions = StopAreaType.generic_name_for_type(sample_station.area_type)
    else
      descriptions = StopAreaType.generic_name_for_type(:pretty_unknown)
    end
    if ! descriptions.has_key?(:short) # short word is needed to fit on the tab
      descriptions[:short] = descriptions[:plural]
    end
    return descriptions
  end
              
      
end