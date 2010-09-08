class RoutesController < ApplicationController
  
  before_filter :process_map_params, :only => [:show]
  
  def show
    @route = Route.full_find(params[:id], params[:scope])
    location_search.add_location(@route) if location_search
    @title = @route.name
    respond_to do |format|
      format.html do 
        map_params_from_location(@route.points)
      end
      format.atom do  
        @campaigns = @route.campaigns.confirmed
        render :template => 'shared/campaigns.atom.builder', :layout => false 
      end
    end
  end
  
end