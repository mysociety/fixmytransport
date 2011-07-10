class ServicesController < ApplicationController
  
  include ApplicationHelper
  caches_page :in_area
  
  def in_area
    map_height = (params[:height].to_i or MAP_HEIGHT)
    map_width = (params[:width].to_i or MAP_WIDTH)
    map_height = MAP_HEIGHT if ! ALL_HEIGHTS.include? map_height
    map_width = MAP_WIDTH if ! ALL_WIDTHS.include? map_width
    other_locations =  Map.other_locations(params[:lat].to_f, params[:lon].to_f, params[:zoom].to_i, map_height, map_width)
    link_type = params[:link_type].to_sym
    render :json => "#{location_stops_coords(other_locations, small=true, link_type).to_json}"
  end
  
  def request_country
    require 'open-uri'
    gaze = MySociety::Config.get('GAZE_URL', '')
    if gaze != ''
      render :text => open("#{gaze}/gaze-rest?f=get_country_from_ip;ip=#{request.remote_ip}").read.strip
    else
      render :text => ''
    end
  end
  
  private
  
  # none of these actions require user (or any other) session, so skip it
  def current_user(refresh=false)
    nil
  end

end
