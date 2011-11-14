class ProblemsController < ApplicationController

  before_filter :process_map_params, :only => [:show,
                                               :new,
                                               :find_stop,
                                               :find_bus_route,
                                               :find_train_route,
                                               :find_ferry_route,
                                               :find_other_route,
                                               :browse]
  before_filter :find_visible_problem, :only => [:show, :update, :add_comment]
  before_filter :require_problem_reporter, :only => [:convert]
  skip_before_filter :require_beta_password, :only => [:frontpage]
  skip_before_filter :make_cachable, :except => [:issues_index, :index, :show]
  before_filter :long_cache, :except => [:issues_index, :index, :create, :show]

  include FixMyTransport::GeoFunctions

  def issues_index
    @title = t('problems.issues_index.title')
    @issues = WillPaginate::Collection.create((params[:page] or 1), 10) do |pager|
      issues = Problem.find_recent_issues(pager.per_page, :offset => pager.offset)
      # inject the result array into the paginated collection:
      pager.replace(issues)

      unless pager.total_entries
        # the pager didn't manage to guess the total count, do it manually
        pager.total_entries = Campaign.visible.count + Problem.visible.count
      end
    end
  end

  def index
    redirect_to :action => 'issues_index'
  end

  def new
    location = instantiate_location(params[:location_id], params[:location_type])
    if !location
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    @problem = Problem.new(:location => location,
                           :reporter => current_user ? current_user : User.new,
                           :reporter_name => current_user ? current_user.name : '')
    map_params_from_location(@problem.location.points, find_other_locations=false)
    setup_problem_advice(@problem)
  end

  def existing
    @location = instantiate_location(params[:location_id], params[:location_type])
    if !@location
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    @issues = WillPaginate::Collection.create((params[:page] or 1), 10) do |pager|
      issues = Problem.find_recent_issues(pager.per_page, {:offset => pager.offset, :location => @location})
      # inject the result array into the paginated collection:
      pager.replace(issues)

      unless pager.total_entries
        # the pager didn't manage to guess the total count, do it manually
        pager.total_entries = @location.campaigns.visible.count + @location.problems.visible.count
      end
    end
    if @issues.empty?
      redirect_to new_problem_url(:location_id => @location.id, :location_type => @location.type)
    end
    map_params_from_location([@location],
                             find_other_locations=false,
                             PROBLEM_CREATION_MAP_HEIGHT,
                             PROBLEM_CREATION_MAP_WIDTH)
  end

  def frontpage
    beta_username = MySociety::Config.get('BETA_USERNAME', 'username')
    beta_password = MySociety::Config.get('BETA_PASSWORD', 'password')
    if app_status == 'closed_beta'
      if !params[:beta]
        unless authenticate_with_http_basic{ |username, password| username == beta_username && Digest::MD5.hexdigest(password) == beta_password }
          render :template => 'problems/beta', :layout => 'beta'
          return
        end
      end
      authenticate_or_request_with_http_basic('Closed Beta') do |username, password|
        username == beta_username && Digest::MD5.hexdigest(password) == beta_password
      end
    end
    @version = 0
    @title = t('problems.frontpage.title')
  end

  def create
    @problem = Problem.new(params[:problem])
    @problem.responsibilities.each do |responsibility|
      if responsibility.organization_id && !@problem.location.responsible_organizations.include?(responsibility.organization)
        @problem.responsibilities.delete(responsibility)
      end
    end
    @problem.status = :new
    if @problem.valid?
      if current_user
        handle_problem_current_user
      else
        handle_problem_no_current_user
      end
    else
      render_or_return_invalid_problem
    end
  end

  def show
    @commentable = @problem
    map_params_from_location(@problem.location.points, find_other_locations=false)
    @new_comment = Comment.new(:commented => @problem,
                               :user => current_user ? current_user : User.new,
                               :user_name => current_user ? current_user.name : '')
  end

  def convert
    if @problem.status != :new
      if @problem.campaign
        redirect_to(campaign_url(@problem.campaign.id)) and return
      else
        redirect_to problem_url(@problem) and return
      end
    end
    if params[:convert] == 'yes'
      # make sure we have a lock on the record for creating a campaign to prevent duplicates
      Problem.transaction do
        @problem = Problem.find(params[:id], :lock => true)
        @problem.create_new_campaign
        @problem.confirm!
      end
      redirect_to(add_details_campaign_url(@problem.campaign.id)) and return
    elsif params[:convert] == 'no'
      @problem.confirm!
      flash[:notice] = t('problems.convert.thanks')
      redirect_to problem_url(@problem) and return
    end
  end

  def add_comment
    @commentable = @problem
    if request.post?
      @comment = @problem.comments.build(params[:comment])
      @comment.status = :new
      if current_user
        return handle_comment_current_user
      else
        return handle_comment_no_user
      end
    end
    render :template => 'shared/add_comment'
  end

  def find_stop
    @title = t('problems.find_stop.title')
    options = { :find_template => :find_stop,
                :browse_template => :choose_location,
                :map_options => { :mode => :find } }
    return find_area(options)
  end

  def find_route
    @title = t('problems.find_route.find_a_route_title')
  end

  def find_bus_route
    @title = t('problems.find_bus_route.title')
    if params[:show_all]
      @limit = nil
    else
      @limit = 10
    end
    if params[:route_number]
      if params[:route_number].blank? or params[:area].blank?
        @error_message = t('problems.find_bus_route.please_enter_route_number_and_area')
        render :find_bus_route
        return
      end

      # geolocation params are only valid if user did not edit the area name after geolocation
      # autofilled their form
      lat = params[:geo_area_name] == params[:area]? params[:lat] : nil
      lon = params[:geo_area_name] == params[:area]? params[:lon] : nil
      accuracy = params[:geo_area_name] == params[:area]? params[:accuracy] : nil
      if is_valid_lon_lat?(lon, lat)
        accuracy = accuracy.to_i
        geolocation_data = { :lat => lat,
                             :lon => lon,
                             :accuracy => accuracy }
      else
        geolocation_data = {}
      end
      location_search = LocationSearch.new_search!(session_id, :route_number => params[:route_number],
                                                               :location_type => 'Bus route',
                                                               :area => params[:area])
      route_info = Gazetteer.bus_route_from_route_number(params[:route_number],
                                                         params[:area],
                                                         @limit,
                                                         ignore_area=false,
                                                         params[:area_type],
                                                         geolocation_data)
      if route_info[:areas]
        @areas = route_info[:areas]
        @name = params[:area]
        render :choose_area
        return
      end
      if route_info[:routes].empty?
        location_search.fail
        @error_message = t('problems.find_bus_route.route_not_found')
      elsif route_info[:routes].size == 1
        location = route_info[:routes].first
        redirect_to existing_problems_url(:location_id => location.id, :location_type => 'Route')
      else
        if route_info[:error] == :area_not_found
          @error_message = t('problems.find_bus_route.area_not_found_routes', :area => params[:area])
        elsif route_info[:error] == :postcode_not_found
          @error_message = t('problems.find_bus_route.postcode_not_found_routes')
        elsif route_info[:error] == :service_unavailable
          @error_message = t('problems.find_bus_route.postcode_service_not_available')
        elsif route_info[:error] == :route_not_found_in_area
          @error_message = t('problems.find_bus_route.route_not_found_in_area', :area => params[:area],
                                                       :route_number => params[:route_number])
        end
        @locations = []
        route_info[:routes].each do |route|
          route.show_as_point = true
          @locations << route
        end
        map_params_from_location(@locations, find_other_locations=false)
        render :choose_route
        return
      end
    end
  end

  def find_train_route
    @title = t('problems.find_train_route.title')
    @error_messages = Hash.new{ |hash, key| hash[key] = [] }
    if params[:to]
      @from_stop = params[:from]
      @to_stop = params[:to]
      if @to_stop.blank? or @from_stop.blank?
        @error_messages[:base] = [t('problems.find_train_route.please_enter_from_and_to')]
      else
        location_search = LocationSearch.new_search!(session_id, :from => @from_stop,
                                                                 :to => @to_stop,
                                                                 :location_type => 'Train route')
        route_info = Gazetteer.train_route_from_stations(@from_stop,
                                                         params[:from_exact],
                                                         @to_stop,
                                                         params[:to_exact])
        setup_from_and_to_stops(route_info)
        if route_info[:errors]
          location_search.fail
          @error_messages = route_info[:errors]
          render :find_train_route
          return
        else
          #create the subroute
          sub_route = SubRoute.make_sub_route(route_info[:from_stops].first,
                                              route_info[:to_stops].first,
                                              TransportMode.find_by_name('Train'),
                                              route_info[:routes])
          redirect_to existing_problems_url(:location_id => sub_route.id, :location_type => sub_route.class.to_s)
        end
      end
    end
  end

  def find_other_route
    @title = t('problems.find_other_route.title')
    @error_messages = Hash.new{ |hash, key| hash[key] = [] }
    if params[:to]
      @from_stop = params[:from]
      @to_stop = params[:to]
      if @from_stop.blank? or @to_stop.blank?
        @error_messages[:base] << t('problems.find_other_route.please_enter_from_and_to')
      else
        location_search = LocationSearch.new_search!(session_id, :from => @from_stop,
                                                                 :to => @to_stop,
                                                                 :location_type => 'Other route')
        route_info = Gazetteer.other_route_from_stations(@from_stop,
                                                         params[:from_exact],
                                                         @to_stop,
                                                         params[:to_exact])
        setup_from_and_to_stops(route_info)
        if route_info[:errors]
          @error_messages = route_info[:errors]
          location_search.fail
          render :find_other_route
          return
        elsif route_info[:routes].empty?
          location_search.fail
          @error_messages[:base] << t('problems.find_other_route.route_not_found')
        elsif route_info[:routes].size == 1
          location = route_info[:routes].first
          redirect_to existing_problems_url(:location_id => location.id, :location_type => 'Route')
        else
          @locations = route_info[:routes]
          map_params_from_location(@locations, find_other_locations=false)
          render :choose_route
          return
        end
      end
    end
  end

  # currently dupped from find_other_route
  def find_ferry_route
    @title = t('problems.find_ferry_route.title')
    @error_messages = Hash.new{ |hash, key| hash[key] = [] }
    if params[:to]
      @from_stop = params[:from]
      @to_stop = params[:to]
      if @from_stop.blank? or @to_stop.blank?
        @error_messages[:base] << t('problems.find_ferry_route.please_enter_from_and_to')
      else
        location_search = LocationSearch.new_search!(session_id, :from => @from_stop,
                                                                 :to => @to_stop,
                                                                 :location_type => 'Ferry route')
        route_info = Gazetteer.ferry_route_from_stations(@from_stop,
                                                         params[:from_exact],
                                                         @to_stop,
                                                         params[:to_exact])
        setup_from_and_to_stops(route_info)
        if route_info[:errors]
          @error_messages = route_info[:errors]
          location_search.fail
          render :find_ferry_route
          return
        elsif route_info[:routes].empty?
          location_search.fail
          @error_messages[:base] << t('problems.find_ferry_route.route_not_found')
        elsif route_info[:routes].size == 1
          location = route_info[:routes].first
          redirect_to existing_problems_url(:location_id => location.id, :location_type => 'Route')
        else
          @locations = route_info[:routes]
          map_params_from_location(@locations, find_other_locations=false)
          render :choose_route
          return
        end
      end
    end
  end

  def choose_location
  end

  def browse
    @highlight = :has_content
    if params[:name]
      @title = t('problems.browse.title', :area => params[:name])
    else
      @title = t('problems.browse.title_no_name')
    end
    options = { :find_template => :browse,
                :browse_template => :browse_area,
                :map_options => { :mode => :browse } }
    return find_area(options)
  end

  # return a truncated stop (don't need all the data)
  # note: params[:transport_mode] is a canonical string because it's also being used for translation: see fmt_geo.js
  def request_nearest_stop
    if is_valid_lon_lat?(params[:lon], params[:lat]) # don't expose this as a service without a session_id?
      transport_mode = case params[:transport_mode]
        when 'ferry'
          'Ferry'
        when 'other'
          'Tram/Metro'
        when 'train'
          'Train'
      end
      nearest_stop = find_nearest_stop(params[:lon], params[:lat], transport_mode)
      render :json => { :name  => nearest_stop.name,
                        :area => nearest_stop.area,
                        :locality_id => nearest_stop.locality_id }
    else
      render :json => "invalid lon/lat" # harsh
    end
  end


  private

  def find_nearest_stop(lon, lat, transport_mode_name)
    location_search = LocationSearch.new_search!(session_id, :name => "geolocate:#{lon},#{lat}",
                                                             :location_type => 'Stop/station')
    easting, northing = get_easting_northing(lon, lat)
    if ! transport_mode_name.blank?
      return StopArea.find_nearest(lon, lat, transport_mode_name, 1, 1000)
    else
      return Stop.find_nearest(easting, northing, exclude_id = nil)
    end
  end

  def find_area(options)
    if is_valid_lon_lat?(params[:lon], params[:lat])
      nearest_stop = find_nearest_stop(params[:lon], params[:lat], nil)
      if nearest_stop
        map_params_from_location([nearest_stop],
                                 find_other_locations=true,
                                 LARGE_MAP_HEIGHT,
                                 LARGE_MAP_WIDTH,
                                 options[:map_options])
        @locations = [nearest_stop]
        render options[:browse_template]
        return
      else # no nearest stop suggests empty database
        location_search.fail
        @error_message = t('problems.find_stop.please_enter_an_area')
      end
    elsif params[:name]
      if params[:name].blank?
        @error_message = t('problems.find_stop.please_enter_an_area')
        render options[:find_template]
        return
      end
      location_search = LocationSearch.new_search!(session_id, :name => params[:name],
                                                               :location_type => 'Stop/station')
      stop_info = Gazetteer.place_from_name(params[:name], params[:stop_name], options[:map_options][:mode])
      # got back localities
      if stop_info[:localities]
        if stop_info[:localities].size > 1
          @localities = stop_info[:localities]
          @matched_stops_or_stations = stop_info[:matched_stops_or_stations]
          @name = params[:name]
          render :choose_locality
          return
        else
          return render_browse_template(stop_info[:localities], options[:map_options], options[:browse_template])
        end
      # got back district
      elsif stop_info[:district]
        return render_browse_template([stop_info[:district]], options[:map_options], options[:browse_template])
      # got back admin area
      elsif stop_info[:admin_area]
        return render_browse_template([stop_info[:admin_area]], options[:map_options], options[:browse_template])
      # got back stops/stations
      elsif stop_info[:locations]
        if options[:map_options][:mode] == :browse
          return render_browse_template(stop_info[:locations], options[:map_options], options[:browse_template])
        else
          map_params_from_location(stop_info[:locations],
                                   find_other_locations=true,
                                   LARGE_MAP_HEIGHT,
                                   LARGE_MAP_WIDTH,
                                   options[:map_options])
          @locations = stop_info[:locations]
          render options[:browse_template]
          return
        end
      # got back postcode info
      elsif stop_info[:postcode_info]
        postcode_info = stop_info[:postcode_info]
        if postcode_info[:error]
          location_search.fail
          if postcode_info[:error] == :area_not_known
            @error_message = t('problems.find_stop.postcode_area_not_known')
          elsif postcode_info[:error] == :service_unavailable
            @error_message = t('problems.find_stop.postcode_service_unavailable')
          else
            @error_message = t('problems.find_stop.postcode_not_found')
          end
          render options[:find_template]
          return
        else
          @lat = postcode_info[:lat] unless @lat
          @lon = postcode_info[:lon] unless @lon
          @zoom = postcode_info[:zoom] unless @zoom
          map_data = Map.other_locations(@lat, @lon, @zoom, LARGE_MAP_HEIGHT, LARGE_MAP_WIDTH, @highlight)
          @other_locations = map_data[:locations]
          @issues_on_map = map_data[:issues]
          @nearest_issues = map_data[:nearest_issues]
          @distance = map_data[:distance]
          @locations = []
          @find_other_locations = true
          render options[:browse_template]
          return
        end
      else
        # didn't find anything
        location_search.fail
        @error_message = t('problems.find_stop.area_not_found')
        render options[:find_template]
        return
      end
    end

  end

  def is_valid_lon_lat?(lon, lat)
    return !(lon.blank? or lat.blank?) && MySociety::Validate.is_valid_lon_lat(lon, lat)
  end

  def render_browse_template(locations, map_options, template)
    map_params_from_location(locations,
                             find_other_locations=true,
                             LARGE_MAP_HEIGHT,
                             LARGE_MAP_WIDTH,
                             map_options)
    @locations = []
    render template
    return
  end

  def find_visible_problem
    @problem = Problem.visible.find(params[:id])
  end

  def require_problem_reporter
    @problem = Problem.find(params[:id])
    return true if current_user && current_user == @problem.reporter
    render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
    return false
  end

  def setup_from_and_to_stops(route_info)
    if route_info[:from_stops].size > 1
      @from_stops = route_info[:from_stops]
    elsif route_info[:from_stops].size == 1
      @from_stop = route_info[:from_stops].first.name
    end

    if route_info[:to_stops].size > 1
      @to_stops = route_info[:to_stops]
    elsif route_info[:to_stops].size == 1
      @to_stop = route_info[:to_stops].first.name
    end
  end

  def setup_problem_advice(problem)
    advice_params = { :location_type => @template.readable_location_type(problem.location) }
    responsible_orgs = problem.location.responsible_organizations
    emailable_orgs, unemailable_orgs = responsible_orgs.partition{ |org| org.emailable?(problem.location) }

    if responsible_orgs.size == 1
      advice_params[:organization] = @template.org_names(responsible_orgs, t('problems.new.or'))
      advice_params[:organization_unstrong] = @template.org_names(responsible_orgs, t('problems.new.or'), '', '')
    elsif responsible_orgs.size > 1
      advice_params[:organizations] = @template.org_names(responsible_orgs, t('problems.new.or'))
    end
    # don't know who is responsible for the location
    if responsible_orgs.size == 0
      advice = 'problems.new.no_organizations_for_problem'
    # all responsible organizations contactable
    elsif responsible_orgs.size == emailable_orgs.size
      if responsible_orgs.size == 1
        advice = 'problems.new.problem_will_be_sent'
      else
        # for operators you get to choose which to email
        if problem.location.operators_responsible?
          advice = 'problems.new.problem_will_be_sent_multiple_operators'
        else
          # for councils, it goes to all or one depending on category
          advice = 'problems.new.problem_will_be_sent_multiple'
        end
      end
    # no responsible organizations contactable
    elsif emailable_orgs.size == 0
      if responsible_orgs.size == 1
        advice = 'problems.new.no_details_for_organization'
      else
        advice = 'problems.new.no_details_for_organizations'
      end
    # some responsible organizations contactable
    else

      advice_params[:contactable] = @template.org_names(emailable_orgs, t('problems.new.or'))
      advice_params[:uncontactable] = @template.org_names(unemailable_orgs, t('problems.new.or'))

      if problem.location.operators_responsible?
        if unemailable_orgs.size > 2
          advice_params[:uncontactable] = t('problems.new.one_of_the_uncontactable_companies')
        end
        if emailable_orgs.size > 2
          advice_params[:contactable] = t('problems.new.one_of_the_contactable_companies')
        end
        advice = 'problems.new.no_details_for_some_operators'
      else
        advice_params[:councils] = @template.org_names(responsible_orgs, t('problems.new.or'))
        advice = 'problems.new.no_details_for_some_councils'
      end
    end
    @sending_advice = t(advice, advice_params)
  end

  def handle_problem_current_user
    @problem.save
    respond_to do |format|
      format.html do
        redirect_to convert_problem_url(@problem)
        return false
      end
      format.json do
        @json = {}
        @json[:success] = true
        @json[:redirect] = convert_problem_url(@problem)
        render :json => @json
        return false
      end
    end
  end

  def handle_problem_no_current_user
    responsibilities = @problem.responsibilities.map{ |res| "#{res.organization_id}|#{res.organization_type}" }.join(",")
    # encoding the text to avoid YAML issues with multiline strings
    # http://redmine.ruby-lang.org/issues/show/1311
    problem_data = { :action => :create_problem,
                     :subject => @problem.subject,
                     :description => ActiveSupport::Base64.encode64(@problem.description),
                     :text_encoded => true,
                     :location_id => @problem.location_id,
                     :location_type => @problem.location_type,
                     :category => @problem.category,
                     :responsibilities => responsibilities,
                     :notice => t('problems.new.create_account_to_report_problem') }
    session[:next_action] = data_to_string(problem_data)
    respond_to do |format|
      format.html do
        flash[:notice] = problem_data[:notice]
        redirect_to(new_account_url)
      end
      format.json do
        @json = { :success => true,
                  :requires_login => true,
                  :notice => problem_data[:notice],
                  :redirect => new_account_url }
        render :json => @json
        return
      end
    end
  end

  def render_or_return_invalid_problem
    respond_to do |format|
      format.html do
        setup_problem_advice(@problem)
        map_params_from_location(@problem.location.points, find_other_locations=false)
        render :new
      end
      format.json do
        @json = {}
        @json[:success] = false
        add_json_errors(@problem, @json)
        render :json => @json
      end
    end
  end

end