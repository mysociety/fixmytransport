class Admin::StopsController < ApplicationController
  
  layout "admin" 
  
  def autocomplete_for_name
    query = params[:term].downcase
    stops = Stop.find_by_name_or_id(query, params[:transport_mode_id], 20)
    stops = stops.map do |stop| 
      { :id => stop.id, 
        :name => @template.stop_name_for_admin(stop) } 
    end
    render :json => stops
  end

end