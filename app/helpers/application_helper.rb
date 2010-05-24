# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def google_maps_key
    MySociety::Config.get('GOOGLE_MAPS_API_KEY', '')
  end
  
  def transport_mode_radio_buttons
    tags = []
    TransportMode.active.find(:all).each do |transport_mode| 
      tag = radio_button 'problem', 'transport_mode_id', transport_mode.id, {:class => 'transport-mode'}
      tag += transport_mode.name
      tags << tag
    end
    tags.join("\n")
  end
  
  def location_param(param_name)
    h(params[:problem][:location_attributes][param_name]) rescue nil
  end
  
  def location_type_radio_buttons(problem)
    tags = []
    location_types = { 'Stop' => 'Stop', 
                       'StopArea' => 'Station', 
                       'Route' => 'Route'}
              
    location_types.keys.sort.each do |location_class|
      checked = problem.location_type == location_class
      tag = radio_button 'problem', 'location_type', location_class, {:class => 'location-type'}
      tag += location_types[location_class]
      tags << tag
    end
    tags.join("\n")
  end
  
  def map_javascript_include_tags
    tags = []
    tags << javascript_include_tag('jquery-1.4.2.min.js')
    tags << javascript_include_tag('http://openlayers.org/api/OpenLayers.js')
    tags << "<script src=\"http://maps.google.com/maps?file=api&amp;v=2&amp;sensor=false&amp;key=#{google_maps_key}\" type=\"text/javascript\"></script>"
    tags << javascript_include_tag('map.js')
    tags.join("\n")
  end
  
  def stop_js_coords(stop)
     "[#{stop.lat}, #{stop.lon}]"
  end
  
  def location_stops_js locations
    if locations.first.is_a? Route
      array_content = locations.map{|route| route.stops.map{ |stop| stop_js_coords(stop) }.join(',') }.join(',') 
    else
     array_content = locations.map{|stop| stop_js_coords(stop) }.join(',') 
    end
    "[#{array_content}];"
  end
  
  def route_segments_js route
    array_content = [];
    route.display_route_segments.each do |route_segment|
      array_content << "[#{stop_js_coords(route_segment.from_stop)}, #{stop_js_coords(route_segment.to_stop)}]"
    end
    array_content = array_content.join(',')
    "[#{array_content}];"
  end
  
end
