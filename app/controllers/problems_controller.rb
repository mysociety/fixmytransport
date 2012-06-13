class ProblemsController < ApplicationController

  before_filter :process_map_params, :only => [:show,
                                               :new,
                                               :find_stop,
                                               :find_bus_route,
                                               :find_train_route,
                                               :find_ferry_route,
                                               :find_other_route,
                                               :browse,
                                               :atom_link]
  before_filter :find_visible_problem, :only => [:show, :update, :add_comment]
  before_filter :require_problem_reporter, :only => [:convert]
  skip_before_filter :require_beta_password, :only => [:frontpage]
  skip_before_filter :make_cachable, :except => [:issues_index, :index, :show]
  before_filter :long_cache, :except => [:issues_index, :index, :create, :show]
  after_filter :update_problem_users, :only => [:show]

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
    @map_height = PROBLEM_CREATION_MAP_HEIGHT
    @map_width = PROBLEM_CREATION_MAP_WIDTH
    location = instantiate_location(params[:location_id], params[:location_type])
    if !location
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    @problem = Problem.new
    @problem.location = location
    # Are the responsibilities for this problem to be based on an existing problem,
    # rather than on the location?
    if (!params[:reference_id].blank?) &&
    reference_problem = get_reference_problem(params[:reference_id], location)
      @problem.reference_id = reference_problem.id
    end
    map_params_from_location(@problem.location.points, find_other_locations=false,
                             height=@map_height, width=@map_width)
    setup_problem_advice(@problem)
  end

  def existing
    @map_height = PROBLEM_CREATION_MAP_HEIGHT
    @map_width = PROBLEM_CREATION_MAP_WIDTH
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
        pager.total_entries = @location.visible_campaigns.size + @location.visible_problems.size
      end
    end
    if @issues.empty?
      redirect_to new_problem_url(:location_id => @location.persistent_id,
                                  :location_type => @location.class.to_s)
      return
    end
    if params[:source] != 'questionnaire'
      flash.now[:large_notice] = t('problems.existing.intro', :location => @template.at_the_location(@location))
    end
    map_params_from_location([@location],
                             find_other_locations=false,
                             @map_height,
                             @map_width)
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
     @title = t('problems.frontpage.title')
  end

  def create
    @problem = Problem.new(params[:problem])
    if @problem.reference_id && !get_reference_problem(@problem.reference_id, @problem.location)
      @problem.reference = nil
    end
    delete_mismatched_responsibilities(@problem)
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
    @map_height = LOCATION_PAGE_MAP_HEIGHT
    @map_width = LOCATION_PAGE_MAP_WIDTH
    @commentable = @problem
    map_params_from_location(@problem.location.points, find_other_locations=false, @map_height, @map_width)
    @new_comment = Comment.new(:commented => @problem,
                               :user => current_user ? current_user : User.new)

  end

  def convert
    if @problem.status != :new
      if @problem.campaign
        redirect_to(campaign_url(@problem.campaign.id)) and return
      else
        redirect_to problem_url(@problem) and return
      end
    end
    if params[:convert] == 'yes' || @problem.reference
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
    # set a flag so that if the user logs out here, we don't try and bring them back
    @no_redirect_on_logout = true
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
                :map_options => { :mode => :find },
                :map_height => LARGE_MAP_HEIGHT,
                :map_width => LARGE_MAP_WIDTH }
    return find_area(options)
  end

  def find_route
    @title = t('problems.find_route.find_a_route_title')
  end

  def find_bus_route
    @map_height = MAP_HEIGHT
    @map_width = MAP_WIDTH
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
        redirect_to existing_problems_url(:location_id => location.persistent_id, :location_type => 'Route')
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
        map_params_from_location(@locations, find_other_locations=false, @map_height, @map_width)
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
          redirect_to existing_problems_url(:location_id => sub_route.persistent_id,
                                            :location_type => sub_route.class.to_s)
        end
      end
    end
  end

  def find_other_route
    @map_height = MAP_HEIGHT
    @map_width = MAP_WIDTH
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
          redirect_to existing_problems_url(:location_id => location.persistent_id,
                                            :location_type => 'Route')
        else
          @locations = route_info[:routes]
          map_params_from_location(@locations, find_other_locations=false, @map_height, @map_width)
          render :choose_route
          return
        end
      end
    end
  end

  # currently dupped from find_other_route
  def find_ferry_route
    @map_height = MAP_HEIGHT
    @map_width = MAP_WIDTH
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
          redirect_to existing_problems_url(:location_id => location.persistent_id,
                                            :location_type => 'Route')
        else
          @locations = route_info[:routes]
          map_params_from_location(@locations, find_other_locations=false, @map_height, @map_width)
          render :choose_route
          return
        end
      end
    end
  end

  def choose_location
  end

  def atom_link
    @issues_feed_title = atom_feed_title @lon, @lat
    @issues_feed_params = params.clone
    @issues_feed_params['action'] = 'browse'
    @issues_feed_params['format'] = 'atom'
    render :partial => 'shared/atom_link',
           :locals => { :feed_link_text => t('problems.browse.feed_link_text') }
  end

  def browse
    if params[:geolocate] == '1'
      @geolocate_on_load = true
    else
      @geolocate_on_load = false
    end
    @highlight = :has_content
    if params[:name]
      @title = t('problems.browse.title', :area => params[:name])
    else
      @title = t('problems.browse.title_no_name')
    end
    options = { :find_template => :browse,
                :browse_template => :browse_area,
                :map_options => { :mode => :browse },
                :map_height => BROWSE_MAP_HEIGHT,
                :map_width => BROWSE_MAP_WIDTH }
    return find_area(options)
  end

  # return a truncated stop (don't need all the data)
  # note: params[:transport_mode] is a canonical string because it's also being used for translation: see fmt_geo.js
  def request_nearest_stop
    if is_valid_lon_lat?(params[:lon], params[:lat])
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
      return StopArea.find_nearest_current(lon, lat, transport_mode_name)
    else
      return Stop.find_nearest_current(easting, northing, exclude_id = nil)
    end
  end

  def atom_feed_title(lon, lat)
    t('problems.browse.feed_title',
      :longitude => lon,
      :latitude => lat)
  end

  def find_area(options)
    @map_height = options[:map_height]
    @map_width = options[:map_width]
    to_render = nil
    if is_valid_lon_lat?(params[:lon], params[:lat])
      lat = params[:lat].to_f
      lon = params[:lon].to_f
      if lat > BNG_MAX_LAT || lat < BNG_MIN_LAT || lon < BNG_MIN_LON || lon > BNG_MAX_LON
        @error_message = t('problems.find_stop.geolocation_outside_area')
        # don't try to geolocate on page load
        @geolocate_on_load = false
        # don't show geolocate button
        @geolocation_failed = true
        to_render = options[:find_template]
      else
        nearest_stop = find_nearest_stop(params[:lon], params[:lat], nil)
        if nearest_stop
          map_params_from_location([nearest_stop],
                                   find_other_locations=true,
                                   @map_height,
                                   @map_width,
                                   options[:map_options])
          # When finding a location we want to highlight what we found, when
          # browsing, just use it to centre the map
          if options[:map_options][:mode] == :browse
            @locations = []
          else
            @locations = [nearest_stop]
          end
          to_render = options[:browse_template]
        else # no nearest stop suggests empty database
          location_search.fail
          @error_message = t('problems.find_stop.please_enter_an_area')
        end
      end
    elsif params[:name]
      if params[:name].blank?
        @error_message = t('problems.find_stop.please_enter_an_area')
        to_render = options[:find_template]
      else
        location_search = LocationSearch.new_search!(session_id, :name => params[:name],
                                                     :location_type => 'Stop/station')
        stop_info = Gazetteer.place_from_name(params[:name], params[:stop_name], options[:map_options][:mode])
        # got back localities
        if stop_info[:localities]
          if stop_info[:localities].size > 1
            @localities = stop_info[:localities]
            @matched_stops_or_stations = stop_info[:matched_stops_or_stations]
            @name = params[:name]
            to_render = :choose_locality
          else
            setup_browse_template(stop_info[:localities], options[:map_options])
            to_render = options[:browse_template]
          end
          # got back district
        elsif stop_info[:district]
          setup_browse_template([stop_info[:district]], options[:map_options])
          to_render = options[:browse_template]
          # got back admin area
        elsif stop_info[:admin_area]
          setup_browse_template([stop_info[:admin_area]], options[:map_options])
          to_render = options[:browse_template]
          # got back stops/stations
        elsif stop_info[:locations]
          if options[:map_options][:mode] == :browse
            setup_browse_template(stop_info[:locations], options[:map_options])
            to_render = options[:browse_template]
          else
            map_params_from_location(stop_info[:locations],
                                     find_other_locations=true,
                                     @map_height,
                                     @map_width,
                                     options[:map_options])
            @locations = stop_info[:locations]
            to_render = options[:browse_template]
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
            to_render = options[:find_template]
          else
            @lat = postcode_info[:lat] unless @lat
            @lon = postcode_info[:lon] unless @lon
            @zoom = postcode_info[:zoom] unless @zoom
            map_data = Map.other_locations(@lat, @lon, @zoom, @map_height, @map_width, @highlight)
            @other_locations = map_data[:locations]
            @issues_on_map = map_data[:issues]
            @nearest_issues = map_data[:nearest_issues]
            @distance = map_data[:distance]
            @locations = []
            @find_other_locations = true
            to_render = options[:browse_template]
          end
        else
          # didn't find anything
          location_search.fail
          @error_message = t('problems.find_stop.area_not_found')
          to_render = options[:find_template]
        end
      end
    end
    respond_to do |format|
      format.html do
        @issues_feed_params = params.clone
        @issues_feed_params[:format] = 'atom'
        render to_render if to_render
      end
      format.atom do
        @title = atom_feed_title @lon, @lat
        @issues = []
        @issues.concat(@issues_on_map) if @issues_on_map
        @issues.concat(@nearest_issues) if @nearest_issues
        render :template => 'shared/issues.atom.builder', :layout => false
      end
    end
  end

  def is_valid_lon_lat?(lon, lat)
    return !(lon.blank? or lat.blank?) && MySociety::Validate.is_valid_lon_lat(lon, lat)
  end

  def setup_browse_template(locations, map_options)
    map_params_from_location(locations,
                             find_other_locations=true,
                             @map_height,
                             @map_width,
                             map_options)
    @locations = []
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
    if problem.reference
      responsible_orgs = problem.reference.responsible_organizations
    else
      responsible_orgs = problem.location.responsible_organizations
    end

    emailable_orgs, unemailable_orgs = responsible_orgs.partition{ |org| org.emailable?(problem.location) }

    if responsible_orgs.size == 1
      advice_params[:organization] = @template.org_names(responsible_orgs, t('problems.new.or'))
      advice_params[:organization_unstrong] = @template.org_names(responsible_orgs, t('problems.new.or'), '', '')
    elsif responsible_orgs.size > 1
      if problem.reference
        advice_params[:organizations] = @template.org_names(responsible_orgs, t('problems.new.and'))
      else
        advice_params[:organizations] = @template.org_names(responsible_orgs, t('problems.new.or'))
      end
    end
    # don't know who is responsible for the location
    if responsible_orgs.size == 0
      advice = 'problems.new.no_organizations_for_problem'
    # all responsible organizations contactable
    elsif responsible_orgs.size == emailable_orgs.size
      if responsible_orgs.size == 1
        advice = 'problems.new.problem_will_be_sent'
      else
        # for problems made from a reference, it should go to all
        if problem.reference
          advice = 'problems.new.problem_will_be_sent_multiple'
        # for operators you get to choose which to email
        elsif problem.location.operators_responsible? && !problem.reference
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

      if problem.reference
        advice = 'problems.new.no_details_for_some_reference_organizations'
      else
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
    end
    @sending_advice = t(advice, advice_params)
  end

  def handle_problem_current_user
    @problem.reporter = current_user
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
    responsibilities = @problem.responsibilities.map do |responsibility|
      [ responsibility.organization_persistent_id, responsibility.organization_type, 'organization_persistent_id' ].join("|")
    end.join(",")
    # encoding the text to avoid YAML issues with multiline strings
    # http://redmine.ruby-lang.org/issues/show/1311
    problem_data = { :action => :create_problem,
                     :subject => @problem.subject,
                     :description => ActiveSupport::Base64.encode64(@problem.description),
                     :text_encoded => true,
                     :location_persistent_id => @problem.location_persistent_id,
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

  def delete_mismatched_responsibilities(problem)
    if problem.reference
      problem.responsibilities.each do |responsibility|
       if !problem.reference.responsible_organizations.include?(responsibility.organization)
          problem.responsibilities.delete(responsibility)
        end
      end
    else
      problem.responsibilities.each do |responsibility|
        if !problem.location.responsible_organizations.include?(responsibility.organization)
          problem.responsibilities.delete(responsibility)
        end
      end
    end
  end

  def get_reference_problem(reference_id, location)
    reference_problem = Problem.find(:first, :conditions => ['id = ?', reference_id])
    if current_user && reference_problem &&
      reference_problem.reporter == current_user && reference_problem.location == location
      return reference_problem
    end
    return nil
  end

  # record that a user reporting the problem has seen the report page.
  def update_problem_users
    if current_user
      current_user.mark_seen(@problem)
    end
  end
end