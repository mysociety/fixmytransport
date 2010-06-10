class LocationsController < ApplicationController

  def random
    location_search.close if location_search
    instance = model_class.find :first, :offset => rand(model_class.count)
    redirect_to location_url(instance)
  end
  
  def respond
    instance = model_class.find(params[:id])
    location_search.add_response(instance, params[:response]) if location_search  
    if params[:response] == 'success'
     flash[:notice] = t(:location_search_success)
    elsif params[:response] == 'fail'
     flash[:notice] = t(:location_search_failure)
    end
    flash[:notice] += " <a href='#{new_story_url}'>#{t(:try_another)}</a>"
    redirect_to location_url(instance)
  end

  private
  
  def update_location(location, attributes)
    if location.update_attributes(attributes)
      flash[:notice] = t(:confirmation_sent)
      redirect_to location_url(location)
    else
      @new_story = location.stories.detect{ |story| story.new_record? }
      render :show 
    end
  end
  
end