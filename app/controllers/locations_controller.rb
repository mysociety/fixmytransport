class LocationsController < ApplicationController
  
  before_filter :process_map_params, :except => [:in_area]
  
  def show_stop
    @stop = Stop.full_find(params[:id], params[:scope])
    @title = @stop.full_name
    if location_search
      location_search.add_location(@stop) 
    end
    respond_to do |format|
      format.html do 
        map_params_from_location(@stop.points, find_other_locations=true)
      end
      format.atom do  
        @campaigns = @stop.campaigns.confirmed
        render :template => 'shared/campaigns.atom.builder', :layout => false 
      end
    end
  end
  
  def show_stop_area
    @stop_area = StopArea.full_find(params[:id], params[:scope])

    # redirect to a station/ferry terminal url if appropriate
    if params[:type] != :station && StopAreaType.station_types.include?(@stop_area.area_type)
      redirect_to @template.location_url(@stop_area) and return false
    end
    if params[:type] != :bus_station && StopAreaType.bus_station_types.include?(@stop_area.area_type)
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
        map_params_from_location(@stop_area.points, find_other_locations=true)
      end
      format.atom do  
        @campaigns = @stop_area.campaigns.confirmed
        render :template => 'shared/campaigns.atom.builder', :layout => false 
      end
    end
  end
  
  def show_route
    @route = Route.full_find(params[:id], params[:scope])
    location_search.add_location(@route) if location_search
    @title = MySociety::Format.ucfirst(@route.name)
    respond_to do |format|
      format.html do 
        map_params_from_location(@route.points, find_other_locations=false)
      end
      format.atom do  
        @campaigns = @route.campaigns.confirmed
        render :template => 'shared/campaigns.atom.builder', :layout => false 
      end
    end
  end
  
  def in_area
    other_locations =  Map.other_locations(params[:lat].to_f, params[:lon].to_f, params[:zoom].to_i)
    render :json => "#{@template.location_stops_js(other_locations, main=false, small=true)}"
  end

end