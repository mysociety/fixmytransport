class ProblemsController < ApplicationController
  
  def new
    location = params[:location_type].constantize.find(params[:location_id])
    @problem = Problem.new(:location => location, 
                           :reporter => User.new, 
                           :reporter_public => true)
    if location.respond_to? :transport_mode_id
      @problem.transport_mode_id = location.transport_mode_id
    else
      if location_search
        if location.transport_mode_ids.include? location_search.transport_mode_id
          @problem.transport_mode_id = location_search.transport_mode_id
        end
      end
    end
    setup_problem_advice(@problem)
  end
  
  def frontpage
    @title = t(:get_problems_fixed)
    @problem = Problem.new()
  end
  
  def create
    @problem = Problem.new(params[:problem])
    if params[:is_campaign]
      @problem.build_campaign({ :location_id => params[:problem][:location_id], 
                                :location_type => params[:problem][:location_type],
                                :reporter => @problem.reporter })
    end
    
    if @problem.save
      # create task assignment
      @problem.create_assignments
      flash.now[:notice] = t(:confirmation_sent)
      render :confirmation_sent
    else
      render :new
    end
  end
  
  def show
    @problem = Problem.find(params[:id])
    @new_update = Update.new(:problem_id => @problem, :reporter => User.new)
  end

  def confirm
    @problem = Problem.find_by_token(params[:email_token])
    if @problem
      @problem.update_attributes(:status => :confirmed,  
                                 :confirmed_at => Time.now)
      # complete the relevant assignments
      Assignment.complete_problem_assignments(@problem, {'write-to-transport-organization' => {}, 
                                                         'publish-problem' => {}})
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
  
  def find
    @location_search = LocationSearch.new_search!(session_id, params)
    problem_attributes = params[:problem]
    problem_attributes[:location_search] = @location_search
    @problem = Problem.new(problem_attributes)
    if !@problem.valid? 
      @title = t :get_problems_fixed
      render :frontpage
    else
      @problem.location_from_attributes
      if @problem.locations.size == 1
         redirect_to location_url(@problem.locations.first)
      elsif !@problem.locations.empty?
        @problem.locations = @problem.locations.sort_by(&:name)
        location_search.add_choice(@problem.locations)
        @title = t :multiple_locations
        render :choose_location
      else
        @title = t :get_problems_fixed
        render :frontpage
      end
    end
  end
  
  def choose_location
  end
  
  def update
    @problem = Problem.find(params[:id])
    # just accept params for a new update for now
    if @problem.update_attributes({ :updates_attributes => 
                                    { "0" => params[:problem][:updates_attributes]["0"] } })
      flash.now[:notice] = t(:update_confirmation_sent)
      render :confirmation_sent
    else
      @new_update = @problem.updates.detect{ |update| update.new_record? }
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
      else
        advice = :no_details_for_some_organizations
      end
    end
    @sending_advice = t(advice, advice_params)
  end
  
  
end