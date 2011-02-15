class LocationsController < ApplicationController
  
  before_filter :process_map_params, :except => [:in_area]
  include ApplicationHelper
  
  def show_stop
    @stop = Stop.full_find(params[:id], params[:scope])
    @title = @stop.full_name
    respond_to do |format|
      format.html do 
        map_params_from_location(@stop.points, find_other_locations=true)
      end
      format.atom do  
        campaign_feed(@stop)
        return
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
    respond_to do |format|
      format.html do
        map_params_from_location(@stop_area.points, find_other_locations=true)
      end
      format.atom do  
        campaign_feed(@stop_area)
        return 
      end
    end
  end
  
  def show_route
    @route = Route.full_find(params[:id], params[:scope])
    if @route.friendly_id_status.numeric?
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    @title = MySociety::Format.ucfirst(@route.name)
    respond_to do |format|
      format.html do 
        map_params_from_location(@route.points, find_other_locations=false)
      end
      format.atom do  
        campaign_feed(@route)
        return
      end
    end
  end
  
  def show_route_region
    @region = Region.find(params[:id])
    @national_region = Region.find_by_name('Great Britain')
  end
  
  def show_route_regions
    @regions = Region.find(:all, :order => 'name asc')
  end
  
  def in_area
    map_height = (params[:height].to_i or MAP_HEIGHT)
    map_width = (params[:width].to_i or MAP_WIDTH)
    map_height = MAP_HEIGHT if ! [MAP_HEIGHT, LARGE_MAP_HEIGHT].include? map_height
    map_width = MAP_WIDTH if ! [MAP_WIDTH, LARGE_MAP_WIDTH].include? map_width
    other_locations =  Map.other_locations(params[:lat].to_f, params[:lon].to_f, params[:zoom].to_i, map_height, map_width)
    link_type = params[:link_type].to_sym
    render :json => "#{location_stops_js(other_locations, main=false, small=true, link_type)}"
  end

  private
  
  def campaign_feed(source)
    @campaigns = source.campaigns.visible
    render :template => 'shared/campaigns.atom.builder', :layout => false
  end

end