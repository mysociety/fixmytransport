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

end