class Admin::StopsController < ApplicationController
  
  layout "admin" 
  
  def autocomplete_for_name
    query = params[:term].downcase
    stops = Stop.find_by_name_or_id(query, params[:transport_mode_id], 20)
    stops = stops.map do |stop| 
      { :id => stop.id, 
        :name => "#{stop.full_name} #{t(:on)} #{stop.street} #{t(:in)} #{stop.locality_name} (#{stop.id})" } 
    end
    render :json => stops
  end

end