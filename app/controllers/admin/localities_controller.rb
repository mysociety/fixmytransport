class Admin::LocalitiesController < ApplicationController

  def autocomplete_for_name
    query = params[:term].downcase
    localities = Locality.find_by_name_or_id(query, 20)
    localities = localities.map do |locality| 
      { :id => locality.id, 
        :name => locality.name } 
    end
    render :json => localities
  end

end