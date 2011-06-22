class LocationsController < ApplicationController

  before_filter :process_map_params
  before_filter :make_cachable
  include ApplicationHelper

  def show_stop
    @stop = Stop.full_find(params[:id], params[:scope])
    @title = @stop.full_name
    respond_to do |format|
      format.html do
        map_params_from_location(@stop.points,
                                find_other_locations=true,
                                height=LOCATION_PAGE_MAP_HEIGHT,
                                width=LOCATION_PAGE_MAP_WIDTH)
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
        map_params_from_location(@stop_area.points,
                                 find_other_locations=true,
                                 height=LOCATION_PAGE_MAP_HEIGHT,
                                 width=LOCATION_PAGE_MAP_WIDTH)
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
    @title = @route.name
    respond_to do |format|
      format.html do
        map_params_from_location(@route.points,
                                 find_other_locations=false,
                                 height=LOCATION_PAGE_MAP_HEIGHT,
                                 width=LOCATION_PAGE_MAP_WIDTH)
      end
      format.atom do
        campaign_feed(@route)
        return
      end
    end
  end

  def show_sub_route
    @sub_route = SubRoute.find(params[:id])
    if @sub_route.friendly_id_status.numeric?
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    @title = @sub_route.name
    map_params_from_location(@sub_route.points,
                             find_other_locations=false,
                             height=LOCATION_PAGE_MAP_HEIGHT,
                             width=LOCATION_PAGE_MAP_WIDTH)
  end

  def show_route_region
    @region = Region.find(params[:id])
    @national_region = Region.find_by_name('Great Britain')
  end

  def show_route_regions
    @regions = Region.find(:all, :order => 'name asc')
  end

  private

  def campaign_feed(source)
    @campaigns = source.campaigns.visible
    render :template => 'shared/campaigns.atom.builder', :layout => false
  end
  
  def make_cachable
    expires_in 60.seconds, :public => true unless current_user
  end

end