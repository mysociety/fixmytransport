class ProblemsController < ApplicationController
  
  before_filter :process_map_params, :only => [:show, 
                                               :new, 
                                               :find_stop, 
                                               :find_bus_route, 
                                               :find_train_route, 
                                               :find_other_route]
  before_filter :find_visible_problem, :only => [:show, :update]
  
  def new
    location = params[:location_type].constantize.find(params[:location_id])
    @problem = Problem.new(:location => location, 
                           :reporter => current_user ? current_user : User.new, 
                           :reporter_name => current_user ? current_user.name : '')
    map_params_from_location(@problem.location.points, find_other_locations=false)
    setup_problem_advice(@problem)
  end
  
  def frontpage
    @title = t(:get_problems_fixed)
  end
  
  def create
    cleanup_time_params
    @problem = Problem.new(params[:problem])
    @problem.status = :new
    if @problem.is_campaign == "1"
      campaign = @problem.build_campaign({ :location_id => params[:problem][:location_id], 
                                           :location_type => params[:problem][:location_type],
                                           :initiator => @problem.reporter })
      campaign.status = :new
    end
    
    if @problem.valid?
      # save the user account if it doesn't exist, but don't log it in
      @problem.save_reporter
      @problem.save
      # create task assignment
      @problem.create_assignments
      if current_user
        @problem.confirm!
        if @problem.campaign
          redirect_to edit_campaign_url(@problem.campaign)
        else
          flash[:notice] = t(:problem_created)
          redirect_to problem_url(@problem)
        end
      else
        @problem.send_confirmation_email
        @action = t(:your_problem_will_not_be_posted)
        @worry = t(:holding_on_to_problem)
        render 'shared/confirmation_sent'
        return
      end
    else
      map_params_from_location(@problem.location.points, find_other_locations=false)
      render :new
    end
  end
  
  def show
    map_params_from_location(@problem.location.points, find_other_locations=false)
    @new_comment = Comment.new(:commented => @problem, 
                               :user => current_user ? current_user : User.new,
                               :user_name => current_user ? current_user.name : '')
  end

  def confirm
    @problem = Problem.find_by_token(params[:email_token])
    if @problem
      @problem.confirm!
      if @problem.campaign
        redirect_to edit_campaign_url(@problem.campaign, :token => params[:email_token])
      end
    else
      @error = t(:problem_not_found)
    end
  end
  
  def update
    # just accept params for a new comment for now
    if current_user && params[:problem][:comments][:user_attributes].has_key?(:id) && 
      current_user.id != params[:problem][:comments][:user_attributes][:id].to_i
      raise "Comment added with user_id that isn't logged in user"
    end
    @new_comment = @problem.comments.build(params[:problem][:comments])
    @new_comment.status = :new
    if @new_comment.valid? 
      # save the user account if it doesn't exist, but don't log it in
      @new_comment.save_user
      @new_comment.save
      if current_user
        @new_comment.confirm!
        flash[:notice] = t(:thanks_for_update)
        redirect_to problem_url(@problem)
      else
        @new_comment.send_confirmation_email
        @action = t(:your_update_will_not_be_posted)
        @worry = t(:holding_on_to_update)
        render 'shared/confirmation_sent'
        return
      end
    else
      map_params_from_location(@problem.location.points, find_other_locations=false)
      render :show
    end
  end
  
  def find_stop
    @title = t(:find_a_stop_or_station)
    if params[:name]
      if params[:name].blank?
        @error_message = t(:please_enter_an_area)
        render :find_stop
        return
      end
      location_search = LocationSearch.new_search!(session_id, :name => params[:name], 
                                                               :location_type => 'Stop/station')
      stop_info = Gazetteer.place_from_name(params[:name])
      # got back areas
      if stop_info[:localities]
        if stop_info[:localities].size > 1
          @localities = stop_info[:localities]
          @link_type = :find_stop
          @name = params[:name]
          render :choose_locality
          return
        else
          map_params_from_location(stop_info[:localities], 
                                   find_other_locations=true, 
                                   LARGE_MAP_HEIGHT,
                                   LARGE_MAP_WIDTH)
          @locations = []
          render :choose_location
          return
        end
      # got back stops/stations
      elsif stop_info[:locations]
        map_params_from_location(stop_info[:locations],
                                 find_other_locations=true, 
                                 LARGE_MAP_HEIGHT,
                                 LARGE_MAP_WIDTH)
        @locations = stop_info[:locations]
        render :choose_location
        return
      # got back postcode info
      elsif stop_info[:postcode_info]
        postcode_info = stop_info[:postcode_info]
        if postcode_info[:error]
          location_search.fail
          @error_message = t(:postcode_not_found)
          render :find_stop
          return
        else
          @lat = postcode_info[:lat] unless @lat
          @lon = postcode_info[:lon] unless @lon
          @zoom = postcode_info[:zoom] unless @zoom
          @other_locations = Map.other_locations(@lat, @lon, @zoom, LARGE_MAP_HEIGHT, LARGE_MAP_WIDTH)
          @locations = []
          @find_other_locations = true
          render :choose_location
          return
        end
      else
        # didn't find anything
        location_search.fail
        @error_message = t(:area_not_found)
        render :find_stop
        return
      end
    end
  end
  
  def find_route
  end
  
  def find_bus_route
    @title = t(:finding_a_bus_route)
    if params[:show_all]
      @limit = nil
    else
      @limit = 10
    end
    if params[:route_number]
      if params[:route_number].blank? or params[:area].blank?
        @error_message = t(:please_enter_route_number_and_area)
        render :find_bus_route 
        return
      end
      location_search = LocationSearch.new_search!(session_id, :route_number => params[:route_number], 
                                                               :location_type => 'Bus route',
                                                               :area => params[:area])
      route_info = Gazetteer.bus_route_from_route_number(params[:route_number], 
                                                         params[:area], 
                                                         @limit, 
                                                         ignore_area=false,
                                                         params[:area_type])
      if route_info[:areas]
        @areas = route_info[:areas]
        @link_type = :find_bus_route
        @name = params[:area]
        render :choose_area
        return
      end
      if route_info[:routes].empty? 
        location_search.fail
        @error_message = t(:route_not_found)
      elsif route_info[:routes].size == 1
        location = route_info[:routes].first
        redirect_to new_problem_url(:location_id => location.id, :location_type => location.type)
      else 
        if route_info[:error] == :area_not_found
          @error_message = t(:area_not_found_routes, :area => params[:area])
        elsif route_info[:error] == :postcode_not_found
          @error_message = t(:postcode_not_found_routes)
        elsif route_info[:error] == :route_not_found_in_area
          @error_message = t(:route_not_found_in_area, :area => params[:area], 
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
    @error_messages = []
    if params[:to]
      @from_stop = params[:from]
      @to_stop = params[:to]
      if @to_stop.blank? or @from_stop.blank?
        @error_messages = [t(:please_enter_from_and_to)]
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
          @error_messages = route_info[:errors].map{ |message| t(message) }
          render :find_train_route
          return
        else
          #create the subroute
          sub_route = SubRoute.make_sub_route(route_info[:from_stops].first, 
                                              route_info[:to_stops].first,
                                              TransportMode.find_by_name('Train'))
          route_info[:routes].each do |route|
            RouteSubRoute.create!(:route => route, 
                                  :sub_route => sub_route)
          end
          redirect_to new_problem_url(:location_id => sub_route.id, :location_type => sub_route.class.to_s)
        end
      end
    end
  end
  
  def find_other_route
    @error_messages = []
    if params[:to]
      @from_stop = params[:from]
      @to_stop = params[:to]
      if @from_stop.blank? or @to_stop.blank?
        @error_messages << t(:please_enter_from_and_to)
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
          @error_messages = route_info[:errors].map{ |message| t(message) }
          location_search.fail
          render :find_other_route
          return
        elsif route_info[:routes].empty? 
          location_search.fail
          @error_messages << t(:route_not_found)
        elsif route_info[:routes].size == 1
          location = route_info[:routes].first
          redirect_to new_problem_url(:location_id => location.id, :location_type => location.type)
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
  
  private 
  
  def find_visible_problem
    @problem = Problem.one_off.visible.find(params[:id])
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
    num_organizations = problem.responsible_organizations.size
    if num_organizations == 1
      advice_params[:organization] = @template.org_names(problem, :responsible_organizations, t(:and))
    elsif num_organizations > 1      
      if problem.operators_responsible?
        advice_params[:organization] = "the operator you select"
      else
        advice_params[:organization] = @template.org_names(problem, :responsible_organizations, t(:or))
      end
    elsif num_organizations == 0
      advice_params[:organization] = "the organization responsible for this #{@template.readable_location_type(problem.location)}"
    end
    advice = :problem_will_be_sent
    @sending_advice = t(advice, advice_params)
  end
  
  def cleanup_time_params
    # fix for https://rails.lighthouseapp.com/projects/8994/tickets/4346
    # from http://www.ruby-forum.com/topic/100815
    if params[:problem]['time(4i)'] && ! params[:problem]['time(4i)'].blank? && 
      params[:problem]['time(5i)'] && !params[:problem]['time(5i)'].blank?
      params[:problem][:time] = "#{params[:problem]['time(4i)']}:#{params[:problem]['time(5i)']}:00"
    end
    (1..5).each do |num|
      params[:problem].delete("time(#{num}i)")
    end
  end
end