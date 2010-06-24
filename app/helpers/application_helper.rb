# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def google_maps_key
    MySociety::Config.get('GOOGLE_MAPS_API_KEY', '')
  end
  
  def transport_mode_radio_buttons(model_name, location=nil)
    tags = []
    if location
      available_modes = location.transport_modes
    else
      available_modes = TransportMode.active.find(:all)
    end
    if available_modes.size == 1
      input = hidden_field(model_name, 'transport_mode_id', :value => available_modes.first.id)
      input += available_modes.first.name
    else
      available_modes.each do |transport_mode| 
        tag = radio_button model_name, 'transport_mode_id', transport_mode.id, {:class => 'transport-mode'}
        tag += transport_mode.name
        tags << tag
      end
      input = tags.join("\n")
    end
    input
  end
  
  def location_param(param_name)
    h(params[:story][:location_attributes][param_name]) rescue nil
  end
  
  def location_type_radio_buttons(story)
    tags = []
    location_types = { 'Stop' => 'Stop', 
                       'StopArea' => 'Station', 
                       'Route' => 'Route'}
              
    location_types.keys.sort.each do |location_class|
      checked = story.location_type == location_class
      tag = radio_button 'story', 'location_type', location_class, {:class => 'location-type'}
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
    "[#{stop.lat}, #{stop.lon}, #{stop.id}, '#{stop_url(stop.locality, stop)}', '#{escape_javascript(stop.description)}']"
  end
  
  def location_stops_js locations
    array_content = []
    locations.each do |location|
      if location.is_a? Route or location.is_a? StopArea
        array_content <<  "[#{location.stops.map{ |stop| stop_js_coords(stop) }.join(',')}]" 
      else
       array_content << stop_js_coords(location) 
      end
    end
    "[#{array_content.join(',')} ];"
  end
  
  def terminus_text(route)
    text = ''
    return text if route.stops.empty?
    terminuses = route.terminuses
    if terminuses.empty?
      terminuses = [route.stops.first]
    end
    stop_names = []
    terminus_links = []
    terminuses.each do |stop| 
      stop_name = stop.name_without_suffix(route.transport_mode)
      stop_area = stop.area
      link_text = stop_name
      if stop_name != stop_area
        link_text += " in #{stop_area}"
      end
      terminus_links << link_to(link_text, stop_url(stop.locality, stop)) unless stop_names.include? link_text
      stop_names << link_text
    end
    if terminus_links.size > 1
      text += "Between " 
      text += terminus_links.to_sentence(:last_word_connector => ' and ') 
    else
      text += "From "
      text += terminus_links.first
    end
    text += "."    
  end
  
end
