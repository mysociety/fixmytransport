class ProblemsController < ApplicationController
  
  before_filter :process_map_params, :only => [:show, :new, :find]
  
  def new
    location = params[:location_type].constantize.find(params[:location_id])
    @problem = Problem.new(:location => location, 
                           :reporter => current_user ? current_user : User.new, 
                           :reporter_public => true, 
                           :reporter_name => current_user ? current_user.name : '')
    if location.respond_to? :transport_mode_id
      @problem.transport_mode_id = location.transport_mode_id
    else
      if location_search
        if location.transport_mode_ids.include? location_search.transport_mode_id
          @problem.transport_mode_id = location_search.transport_mode_id
        end
      end
    end
    map_params_from_location(@problem.location.points, find_other_locations=false)
    setup_problem_advice(@problem)
  end
  
  def frontpage
    @title = t(:get_problems_fixed)
  end
  
  def create
    @problem = Problem.new(params[:problem])
    if params[:is_campaign]
      @problem.build_campaign({ :location_id => params[:problem][:location_id], 
                                :location_type => params[:problem][:location_type],
                                :status => :new, 
                                :initiator => @problem.reporter })
    end
    
    if @problem.valid?
      # save the user account if it doesn't exist, but don't log it in
      @problem.save_reporter
      @problem.save
      # create task assignment
      @problem.create_assignments
      @action = t(:your_problem_will_not_be_posted)
      @worry = t(:holding_on_to_problem)
      render 'shared/confirmation_sent'
    else
      map_params_from_location(@problem.location.points, find_other_locations=false)
      render :new
    end
  end
  
  def show
    @problem = Problem.confirmed.find(params[:id])
    map_params_from_location(@problem.location.points, find_other_locations=false)
    @new_update = Update.new(:problem_id => @problem, 
                             :reporter => current_user ? current_user : User.new,
                             :reporter_name => current_user ? current_user.name : '')
  end

  def confirm
    @problem = Problem.find_by_token(params[:email_token])
    if @problem
      @problem.update_attributes(:status => :confirmed,  
                                 :confirmed_at => Time.now)
      # complete the relevant assignments
      Assignment.complete_problem_assignments(@problem, {'publish-problem' => {}})
      if !@problem.emailable_organizations.empty?
        data = {:organizations => @problem.organization_info(:emailable_organizations) }
        Assignment.complete_problem_assignments(@problem, {'write-to-transport-organization' => data })
      end
      if @problem.campaign
        redirect_to edit_campaign_url(@problem.campaign, :token => params[:email_token])
      end
    else
      @error = t(:problem_not_found)
    end
  end
  
  def confirm_update  
    @update = Update.find_by_token(params[:email_token])
    if @update
      @update.confirm!
    else
      @error = t(:update_not_found)
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
      stop_info = Gazetteer.place_from_name(params[:name])
      # got back areas
      if stop_info[:localities]
        if stop_info[:localities].size > 1
          @localities = stop_info[:localities]
          render :choose_locality
          return
        else
          map_params_from_location(stop_info[:localities], find_other_locations=true)
          @locations = []
          render :choose_location
          return
        end
      # got back stops/stations
      elsif stop_info[:locations]
        map_params_from_location(stop_info[:locations], find_other_locations=true)
        @locations = stop_info[:locations]
        render :choose_location
        return
      # got back postcode info
      elsif stop_info[:postcode_info]
        postcode_info = stop_info[:postcode_info]
        if postcode_info[:error]
          @error_message = t(:postcode_not_found)
          render :find_stop
          return
        else
          @lat = postcode_info[:lat]
          @lon = postcode_info[:lon]
          @zoom = postcode_info[:zoom]
          @other_locations = Map.other_locations(@lat, @lon, @zoom)
          @locations = []
          @find_other_locations = true
          render :choose_location
          return
        end
      else
        # didn't find anything
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
    if params[:route_number]
      if params[:route_number].blank? or params[:area].blank?
        @error_message = t(:please_enter_route_number_and_area)
        render :find_bus_route 
        return
      end
      route_info = Gazetteer.bus_route_from_route_number(params[:route_number], params[:area], limit=10)
      if route_info[:routes].empty? 
        @error_message = t(:route_not_found)
      elsif route_info[:routes].size == 1
        redirect_to @template.location_url(route_info[:routes].first)
      else 
        if route_info[:error] == :area_not_found
          @error_message = t(:area_not_found_routes)
        elsif route_info[:error] == :postcode_not_found
          @error_message = t(:postcode_not_found_routes)
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
    if params[:to]
      if params[:to].blank? or params[:from].blank?
        @error_message = t(:please_enter_from_and_to)
      else
        route_info = Gazetteer.train_route_from_stations_and_time(params[:from], params[:to], params[:time])
        if route_info[:routes].empty? 
          @error_message = t(:route_not_found)
        elsif route_info[:routes].size == 1
          redirect_to @template.location_url(route_info[:routes].first)
        else
          @locations = route_info[:routes]
          render :choose_train_route
          return 
        end
      end
    end
  end
  
  def choose_location
  end
  
  def update
    @problem = Problem.find(params[:id])
    # just accept params for a new update for now
    @new_update = @problem.updates.build(params[:problem][:updates])
    if @new_update.valid? 
      # save the user account if it doesn't exist, but don't log it in
      @new_update.save_reporter
      @new_update.save
      @action = t(:your_update_will_not_be_posted)
      @worry = t(:holding_on_to_update)
      render 'shared/confirmation_sent'
    else
      render :show
    end
  end
  
  private 
  
  def setup_problem_advice(problem)
    advice_params = { :location_type => @template.readable_location_type(problem.location) }
    num_organizations = problem.responsible_organizations.size
    num_organizations_with_email = 0
   
    problem.responsible_organizations.each do |organization| 
      if organization.emailable?
        num_organizations_with_email += 1
      end
    end
    if num_organizations == 1
      advice_params[:organization] = @template.org_names(problem, :responsible_organizations, t(:or))
      advice_params[:organization_unstrong] = @template.org_names(problem, :responsible_organizations, t(:or), '', '')
    elsif num_organizations > 1
      advice_params[:organizations] = @template.org_names(problem, :responsible_organizations, t(:or))
    end
    # don't know who is responsible for the location
    if num_organizations == 0
      advice = :no_organizations_for_problem
    # all responsible organizations contactable
    elsif num_organizations == num_organizations_with_email
      if num_organizations == 1
        advice = :problem_will_be_sent
      else
        # for operators you get to choose which to email
        if problem.operators_responsible? 
          advice = :problem_will_be_sent_multiple_operators
        else
          # for councils, it goes to all or one depending on category
          advice = :problem_will_be_sent_multiple
        end
      end
    # no responsible organizations contactable
    elsif num_organizations_with_email == 0
      if num_organizations == 1
        advice = :no_details_for_organization
      else
        advice = :no_details_for_organizations
      end
    # some responsible organizations contactable
    else
      advice_params[:contactable] = @template.org_names(problem, :emailable_organizations, t(:or))
      advice_params[:uncontactable] = @template.org_names(problem, :unemailable_organizations, t(:or)) 
      if problem.operators_responsible? 
        advice = :no_details_for_some_operators
      elsif problem.councils_responsible?
        advice_params[:councils] = @template.org_names(problem, :responsible_organizations, t(:or))
        advice = :no_details_for_some_councils
      else
        advice = :no_details_for_some_organizations
      end
    end
    @sending_advice = t(advice, advice_params)
  end
  
  
end