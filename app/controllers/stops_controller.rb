class StopsController < ApplicationController
  
  def show
    @stop = Stop.full_find(params[:id], params[:scope])
    @title = @stop.full_name
    if location_search
      location_search.add_location(@stop) 
    end
    respond_to do |format|
      format.html
      format.atom do  
        @campaigns = @stop.campaigns.confirmed
        render :template => 'shared/campaigns.atom.builder', :layout => false 
      end
    end
  end

end