# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def google_maps_key
    MySociety::Config.get('GOOGLE_MAPS_API_KEY', '')
  end
  
  def transport_mode_radio_buttons(context, model_name, location=nil)
    tags = []
    if location
      available_modes = location.transport_modes
    else
      available_modes = TransportMode.active.find(:all)
    end
    tags << %Q[<div id="transport-mode-radio">]
    if available_modes.size == 1
      tags << context.hidden_field('transport_mode_id', :value => available_modes.first.id)
    else
      tags << %Q[<div class="transport-mode">] 
      available_modes.each do |transport_mode| 
        tag = context.radio_button 'transport_mode_id', transport_mode.id, {:class => 'transport-mode', :onchange => "changeMode('#{transport_mode.css_name}')"}
        tag += context.label "transport_mode_id_#{transport_mode.id}", transport_mode.name
        tag = %Q[<div class="transport-bg-#{transport_mode.css_name}">#{tag}</div>]
        tags << tag
      end
      tags << "</div>"
    end
    tags << "</div>"
    tags.join("\n")
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
  
  # options:
  #  no_jquery - don't include a tag for the main jquery js file
  def map_javascript_include_tags(options={})
    tags = []
    unless options[:no_jquery]
      tags << javascript_include_tag('jquery-1.4.2.min.js')
    end
    tags << javascript_include_tag('http://openlayers.org/api/OpenLayers.js')
    tags << "<script src=\"http://maps.google.com/maps?file=api&amp;v=2&amp;sensor=false&amp;key=#{google_maps_key}\" type=\"text/javascript\"></script>"
    tags << javascript_include_tag('map.js')
    tags.join("\n")
  end
  
  def stop_js_coords(stop)
    "[#{stop.lat}, #{stop.lon}, #{stop.id}, '#{stop_url(stop.locality, stop)}', '#{escape_javascript(stop.description)}']"
  end
  
  def route_segment_js(route)
    segments_js = route.route_segments.map do |segment| 
      "[#{stop_js_coords(segment.from_stop)}, #{stop_js_coords(segment.to_stop)}, #{segment.id}]"
    end
    "[#{segments_js.join(',')}]"
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
  
  def stop_name_for_admin(stop)
    name = stop.full_name
    if ! stop.street.blank?
      name += " #{t(:on_street, :street => stop.street)}"
    end 
    name += " #{t(:in_locality, :locality => stop.locality_name)} (#{stop.id})"
    name
  end
  
  def departures_link(stop)
    modes = stop.transport_mode_names
    if modes.include? 'Bus' or modes.include? 'Coach' or modes.include? 'Ferry'
      return link_to(t(:live_departures), "http://mytraveline.mobi/departureboard?stopCode=#{stop.atco_code}")
    else
      return ''
    end
  end
  
  def external_search_link(text)
    "http://www.google.co.uk/search?ie=UTF-8&q=#{CGI.escape(text)}"
  end
end
