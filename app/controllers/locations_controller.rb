class LocationsController < ApplicationController
  before_filter :process_map_params
  include ApplicationHelper

  def show_stop
    begin
      @stop = Stop.full_find(params[:id], params[:scope])
    # handle params matching a stop in the previous generation with a redirect to the successor
    # if there is one
    rescue ActiveRecord::RecordNotFound => error
      if @successor = Stop.find_successor(params[:id], :scope => params[:scope], :include => [:locality])
        redirect_previous(@successor) and return
      end
      raise
    end
    @commentable = @stop
    @title = @stop.full_name
    respond_to do |format|
      format.html do
        @map_height = PROBLEM_CREATION_MAP_HEIGHT
        @map_width = PROBLEM_CREATION_MAP_HEIGHT
        map_params_from_location(@stop.points,
                                find_other_locations=true,
                                height=@map_height,
                                width=@map_width)
        return false
      end
      format.atom do
        campaign_feed(@stop)
        return
      end
    end
  end

  def show_stop_area
    begin
      @stop_area = StopArea.full_find(params[:id], params[:scope])
    # handle params matching a stop area in the previous generation with a redirect to the successor
    # if there is one
    rescue ActiveRecord::RecordNotFound => error
      if @successor = StopArea.find_successor(params[:id], :scope => params[:scope], :include => [:locality])
        redirect_previous(@successor) and return
      end
      raise
    end
    @commentable = @stop_area
    # Don't display a station part stop_area - redirect to its parent
    station_root = @stop_area.station_root()
    if station_root
      redirect_to(@template.location_url(station_root), :status => :moved_permanently) and return false
    end
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
        @map_height = PROBLEM_CREATION_MAP_HEIGHT
        @map_width = PROBLEM_CREATION_MAP_WIDTH
        map_params_from_location(@stop_area.points,
                                 find_other_locations=true,
                                 height=@map_height,
                                 width=@map_width)
      end
      format.atom do
        campaign_feed(@stop_area)
        return
      end
    end
  end

  def show_route
    @route = Route.full_find(params[:id], params[:scope])
    @commentable = @route
    if @route.friendly_id_status.numeric?
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    @title = @route.name
    respond_to do |format|
      format.html do
        @map_height = PROBLEM_CREATION_MAP_HEIGHT
        @map_width = PROBLEM_CREATION_MAP_WIDTH
        map_params_from_location(@route.points,
                                 find_other_locations=false,
                                 height=@map_height,
                                 width=@map_width)
      end
      format.atom do
        campaign_feed(@route)
        return
      end
    end
  end

  def show_sub_route
    @sub_route = SubRoute.find(params[:id])
    @commentable = @sub_route
    if @sub_route.friendly_id_status.numeric?
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    @title = @sub_route.name
    @map_height = PROBLEM_CREATION_MAP_HEIGHT
    @map_width = PROBLEM_CREATION_MAP_WIDTH
    map_params_from_location(@sub_route.points,
                             find_other_locations=false,
                             height=@map_height,
                             width=@map_width)
  end

  def show_route_region
    @region = Region.find(params[:id])
    @national_region = Region.find_by_name('Great Britain')
    if @region == @national_region
      @title = t('locations.show_route_region.national_routes_title')
    else
      @title = t('locations.show_route_region.routes_in', :region => @region.name)
    end
  end

  def show_route_regions
    @title = t('locations.show_route_regions.routes_by_region')
    @regions = Region.find(:all, :order => 'name asc')
  end

  def add_comment_to_route
    @commentable = Route.find(params[:id], :scope => params[:scope])
    return add_comment_to_location
  end

  def add_comment_to_stop
    @commentable = Stop.find(params[:id], :scope => params[:scope])
    return add_comment_to_location
  end

  def add_comment_to_stop_area
    @commentable = StopArea.find(params[:id], :scope => params[:scope])
    return add_comment_to_location
  end

  def add_comment_to_sub_route
    @commentable = SubRoute.find(params[:id])
    return add_comment_to_location
  end

  private

  def redirect_previous(previous)
    new_params = { :id => previous.to_param, :scope => previous.locality.to_param }
    redirect_to params.merge(new_params), :status => :moved_permanently
  end

  def campaign_feed(source)
    @campaigns = source.campaigns.visible
    render :template => 'shared/campaigns.atom.builder', :layout => false
  end

  def add_comment_to_location
    if request.post?
      @comment = @commentable.comments.build(params[:comment])
      @comment.status = :new
      if current_user
        return handle_comment_current_user
      else
        return handle_comment_no_user
      end
    end
    render :template => 'shared/add_comment'
  end

end