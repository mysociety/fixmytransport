class StopsController < ApplicationController
  
  before_filter :process_map_params, :only => [:show]
  
  def show
    @stop = Stop.full_find(params[:id], params[:scope])
    @title = @stop.full_name
    if location_search
      location_search.add_location(@stop) 
    end
    respond_to do |format|
      format.html do 
        map_params_from_location(@stop.points)
      end
      format.atom do  
        @campaigns = @stop.campaigns.confirmed
        render :template => 'shared/campaigns.atom.builder', :layout => false 
      end
    end
  end

end