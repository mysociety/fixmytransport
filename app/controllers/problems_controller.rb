class ProblemsController < ApplicationController
  
  def new
    location = params[:location_type].constantize.find(params[:location_id])
    @problem = Problem.new(:location => location, :reporter => User.new(:public => true))
    if location.respond_to? :transport_mode_id
      @problem.transport_mode_id = location.transport_mode_id
    else
      if location_search
        if location.transport_mode_ids.include? location_search.transport_mode_id
          @problem.transport_mode_id = location_search.transport_mode_id
        end
      end
    end
    setup_problem_advice
  end
  
  def frontpage
    @title = t(:get_problems_fixed)
    @problem = Problem.new()
  end
  
  def create
    @problem = Problem.new(params[:problem])
    if @problem.save
      # create task assignment
      @problem.create_assignment
      flash[:notice] = t(:confirmation_sent)
      redirect_to location_url(@problem.location)
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
      Assignment.complete_problem_assignments(@problem, ['write-to-transport-operator', 
                                                         'publish-problem'])
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
      flash[:notice] = t(:update_confirmation_sent)
      redirect_to problem_url(@problem)
    else
      @new_update = @problem.updates.detect{ |update| update.new_record? }
      render :show
    end
  end
  
  private 
  
  def setup_problem_advice
    advice_params = { :location_type => @template.readable_location_type(@problem.location) }
    num_operators = @problem.location.operators.size
    num_operators_with_email = @problem.location.operators.with_email.size
    # don't know who operates the location
    if num_operators == 0
      advice = :no_operators_for_problem
    # all operators contactable
    elsif num_operators == num_operators_with_email
      if num_operators == 1
        advice_params[:operator] = @problem.location.operators.first.name
        advice = :problem_will_be_sent
      else
        advice = :problem_will_be_sent_multiple
      end
    # no operators contactable
    elsif num_operators_with_email == 0
      if num_operators == 1
        advice = :no_details_for_operator
      else
        advice = :no_details_for_operators
      end
    # some operators contactable
    else
      advice_params[:contactable] = @template.contactable_operator_names(@problem.location, t(:or))
      advice_params[:uncontactable] = @template.uncontactable_operator_names(@problem.location, t(:or)) 
      advice = :no_details_for_some_operators
    end
    @sending_advice = t(advice, advice_params)
  end
  
  
end