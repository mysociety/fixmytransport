class ProblemsController < ApplicationController

  def new
    @title = t :new_story
    @problem = Problem.new()
  end
  
  def index
    @title = t(:recent_stories)
    @problems = Problem.paginate( :page => params[:page], 
                                  :conditions => ['confirmed = ?', true],
                                  :order => 'created_at DESC' )
  end
  
  def find
    @location_search = LocationSearch.new_search!(session_id, params)
    problem_attributes = params[:problem]
    problem_attributes[:location_search] = @location_search
    @problem = Problem.new(problem_attributes)
    if !@problem.valid? 
      @title = t :new_story
      render :new
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
        @title = t :problem_location_not_found
        render :new
      end
    end
  end
  
  def choose_location
  end
  
  def confirm
    @problem = Problem.find_by_token(params[:email_token])
    if !@problem
      @error = t(:story_not_found)
    else
      @problem.toggle!(:confirmed)
    end
  end
  
  def show
    @problem = Problem.find(params[:id])
    @title = @problem.subject
  end
  
  private
  
  rescue_from ActiveRecord::RecordNotFound do
    render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
  end
  
end