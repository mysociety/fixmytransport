class StopAreasController < ApplicationController
  
  before_filter :process_map_params, :only => [:show]
  
  def show
    @stop_area = StopArea.full_find(params[:id], params[:scope])

    # redirect to a station/ferry terminal url if appropriate
    if params[:type] != :station && StopAreaType.station_types.include?(@stop_area.area_type)
      redirect_to @template.location_url(@stop_area) and return false
    end
    if params[:type] != :ferry_terminal && StopAreaType.ferry_terminal_types.include?(@stop_area.area_type)
      redirect_to @template.location_url(@stop_area) and return false
    end
    
    @title = @stop_area.name
    if location_search
      location_search.add_location(@stop_area) 
    end
    respond_to do |format|
      format.html do
        map_params_from_location(@stop_area.points)
      end
      format.atom do  
        @campaigns = @stop_area.campaigns.confirmed
        render :template => 'shared/campaigns.atom.builder', :layout => false 
      end
    end
  end
  
end