class ServicesController < ApplicationController

  include ApplicationHelper
  skip_before_filter :make_cachable
  before_filter :long_cache, :except => [:request_country]

  def in_area
    lat = params[:lat].to_f
    lon = params[:lon].to_f
    if lat > 90.0 or lat < -90.0 or lon < -180 or lon > 180
      render :json => {}
      return
    end
    map_height = (params[:height].to_i or MAP_HEIGHT)
    map_width = (params[:width].to_i or MAP_WIDTH)
    map_height = MAP_HEIGHT if ! ALL_HEIGHTS.include? map_height
    map_width = MAP_WIDTH if ! ALL_WIDTHS.include? map_width
    highlight = params[:highlight].blank? ? nil : params[:highlight].to_sym
    map_data = Map.other_locations(params[:lat].to_f,
                                   params[:lon].to_f,
                                   params[:zoom].to_i,
                                   map_height,
                                   map_width,
                                   highlight)
    other_locations = map_data[:locations]
    link_type = params[:link_type].to_sym
    @issues_on_map = map_data[:issues]
    @nearest_issues = map_data[:nearest_issues]
    @distance = map_data[:distance]
    issue_content = render_to_string :partial => "shared/issues_in_area"
    area_data = { :locations => location_stops_coords(other_locations, small=true, link_type, highlight),
                  :issue_content => issue_content }
    render :json => area_data.to_json
  end

  def request_country
    require 'open-uri'
    gaze = MySociety::Config.get('GAZE_URL', '')
    if gaze != ''
      render :text => open("#{gaze}/gaze-rest?f=get_country_from_ip;ip=#{request.remote_ip}").read.strip
    else
      render :text => 'GB'
    end
  end

  private

  # none of these actions require user (or any other) session, so skip it
  def current_user(refresh=false)
    nil
  end

end
