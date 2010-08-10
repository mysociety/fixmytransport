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
  end
  
  def frontpage
    @title = t(:get_problems_fixed)
    @problem = Problem.new()
  end
  
  def create
    @problem = Problem.new(params[:problem])
    if @problem.save
      # create task assignment
      assignment_attributes = { :task_type_name => 'write-to-transport-operator', 
                                :status => :in_progress,
                                :user => @problem.reporter,
                                :problem => @problem }
      Assignment.create_assignment(assignment_attributes)
      flash[:notice] = t(:confirmation_sent)
      redirect_to location_url(@problem.location)
    else
      render :new
    end
  end
  
  def show
    @problem = Problem.find(params[:id])
  end

  def confirm
    @problem = Problem.find_by_token(params[:email_token])
    if @problem
      @problem.update_attributes(:confirmed => true,  
                                 :confirmed_at => Time.now)
      # complete the assignment
      assignment = Assignment.complete_problem_assignment(@problem, 'write-to-transport-operator')
    else
      @error = t(:problem_not_found)
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
  
  
end