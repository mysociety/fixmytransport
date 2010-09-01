class RoutesController < ApplicationController
  
  def show
    @route = Route.full_find(params[:id], params[:scope])
    location_search.add_location(@route) if location_search
    @title = @route.name
    respond_to do |format|
      format.html
      format.atom do  
        @campaigns = @route.campaigns.confirmed
        render :template => 'shared/campaigns.atom.builder', :layout => false 
      end
    end
  end
  
end