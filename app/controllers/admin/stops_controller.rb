class Admin::StopsController < ApplicationController
  
  layout "admin" 
  
  def autocomplete_for_name
    query = params[:term].downcase
    stops = Stop.find_by_name_or_id(query, params[:transport_mode_id], 20)
    stops = stops.map do |stop| 
      name = stop.full_name
      if ! stop.street.blank?
        name += " #{t(:on_street, :street => stop.street)}"
      end 
      name += " #{t(:in_locality, :locality => stop.locality_name)} (#{stop.id})"
      { :id => stop.id, 
        :name => name } 
    end
    render :json => stops
  end

end