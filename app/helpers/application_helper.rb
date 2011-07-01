# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def google_maps_key
    MySociety::Config.get('GOOGLE_MAPS_API_KEY', '')
  end
  
  def library_js_link
    javascript_include_tag('jquery-1.5.2.min', 
                           'jquery-ui-1.8.13.custom.min', 
                           'jquery.autofill.min', 
                           'jquery.form.min', 
                           'OpenLayers', 
                           'map', :charset => 'utf-8', :cache => 'libraries')
  end
  
  def admin_library_js_link
     javascript_include_tag('jquery-1.5.2.min', 
                            'jquery-ui-1.8.13.custom.min', 
                            'OpenLayers-admin', 
                            'map',
                            'admin', :charset => 'utf-8', :cache => 'admin_libraries')
  end
  
  def main_js_link
    javascript_include_tag('fixmytransport', 'application', 'fb', :charset => 'utf-8', :cache => 'main')
  end
  
  # options:
  #  no_jquery - don't include a tag for the main jquery js file
  def map_javascript_include_tags(options={})
    tags = []
    tags << "<script src=\"http://maps.google.com/maps?file=api&amp;v=2&amp;sensor=false&amp;key=#{google_maps_key}\" type=\"text/javascript\"></script>"
    tags.join("\n")
  end

  def icon_style(location, center_y, center_offset_y, center_x, center_offset_x, zoom)
    top = Map.lat_to_y_offset(center_y, center_offset_y, location[:lat], zoom) - (location[:height] / 2)
    left = Map.lon_to_x_offset(center_x, center_offset_x, location[:lon], zoom) - (location[:width] / 2)
    "position: absolute; top: #{top}px; left: #{left}px;"
  end

  def icon_height(small)
    small ? SMALL_ICON_HEIGHT : LARGE_ICON_HEIGHT
  end

  def icon_width(small)
    small ? SMALL_ICON_WIDTH : LARGE_ICON_WIDTH
  end

  def stop_coords(stop, small=false, link_type=:location, location=nil, line_only=false)
    location = (location or stop)
    if line_only
      data = { :lat => stop.lat,
               :lon => stop.lon,
               :id => stop.id }
    else
      
      data = { :lat => stop.lat,
               :lon => stop.lon,
               :id => stop.id,
               :url => map_link_url(location, link_type),
               :description => location.description,
               :icon => stop_icon(stop, small),
               :height => icon_height(small),
               :width => icon_width(small) }
    end
    return data
  end

  def stop_icon(location, small=false)
    name = '/images/map-icons/map-'
    if location.is_a? Route
      if location.transport_mode_name == 'Train'
        name += 'train-blue'
      elsif location.transport_mode_name == 'Tram/Metro'
        name += 'tram-green'
      elsif location.transport_mode_name == 'Ferry'
        name += 'boat-orange'
      else
        name += 'bus-magenta'
      end
    else
      if location.respond_to?(:area_type) && location.area_type == 'GRLS'
        name += 'train-blue'
      elsif location.respond_to?(:area_type) && location.area_type == 'GTMU'
        name += 'tram-green'
      elsif location.respond_to?(:area_type) && location.area_type == 'GFTD'
        name += 'boat-orange'
      else
        name += 'bus-magenta'
      end
    end
    
    if small
      name += '-sml' 
    else
      name += '-med'
    end
    return name
  end

  def route_segment_js(route, line_only=false)
    segments_js = route.journey_patterns.map{ |jp| jp.route_segments }.flatten.map do |segment|
      [stop_coords(segment.from_stop, small=true, link_type=:location, location=nil, line_only=line_only),
       stop_coords(segment.to_stop, small=true, link_type=:location, location=nil, line_only=line_only), segment.id]
    end
    segments_js.to_json
  end

  def location_stops_coords(locations, small, link_type)
    array_content = []
    locations.each do |location|
      if location.is_a? Route or location.is_a? SubRoute
        if location.show_as_point
          array_content << stop_coords(location, false, link_type)
        elsif location.is_a? Route and link_type == :problem
          array_content <<  location.points.map{ |stop| stop_coords(stop, true, link_type, location) }
        else
          array_content <<  location.points.map{ |stop| stop_coords(stop, true, link_type) }
        end
      else
       array_content << stop_coords(location, small, link_type)
      end
    end
    array_content
  end

  def stop_name_for_admin(stop)
    name = stop.full_name
    if ! stop.street.blank?
      name += " #{t(:on_street, :street => stop.street)}"
    end
    name += " #{t(:in_locality, :locality => stop.locality_name)} (#{stop.id})"
    name
  end

  def external_search_link(text)
    "http://www.google.co.uk/search?ie=UTF-8&q=#{CGI.escape(text)}"
  end

  def on_or_at_the(location)
    if location.is_a? Route or location.is_a? SubRoute
      return t('shared.problem.on_the')
    elsif location.is_a?(StopArea) && ['GRLS', 'GTMU'].include?(location.area_type)
      return t('shared.problem.at')
    else
      return t('shared.problem.at_the')
    end
  end

  def at_the_location(location)
    location_string = "#{on_or_at_the(location)} #{location.name}"
    if location.is_a?(Stop) && location.transport_mode_names.include?('Bus')
      location_string += " bus/tram stop"
    end
    location_string
  end

  def readable_location_type(location)
    if location.is_a? Stop or location.is_a? StopArea

      # some stops could be bus or tram/metro - call these stops
      if location.is_a?(StopArea)
        if location.area_type == 'GBCS'
          return 'bus/coach station'
        end
      end
      transport_mode_names = location.transport_mode_names
      if transport_mode_names.include? 'Train' or transport_mode_names == ['Tram/Metro']
        return "station"
      end
      if transport_mode_names.include? 'Bus'
        return "stop"
      end
    end
    if location.is_a? TramMetroRoute
      return 'route'
    end
    if location.is_a? SubRoute
      return 'route'
    end
    location.class.to_s.tableize.singularize.humanize.downcase
  end

  def org_names(problem, method, connector, wrapper_start='<strong>', wrapper_end='</strong>')
    return '' unless problem
    names = problem.send(method).map{ |org| "#{wrapper_start}#{org.name}#{wrapper_end}" }
    names.to_sentence(:last_word_connector => " #{connector} ", :two_words_connector => " #{connector} ")
  end

  def operator_links(operators)
    operator_links = operators.map{ |operator| link_to(operator.name, operator_path(operator)) }
    operator_links.to_sentence(:last_word_connector => ' and ', :two_words_connector => ', ')
  end

  def comment_url(comment)
    if comment.commented.is_a? Problem
      problem_url(comment.commented, :anchor => "comment_#{comment.id}")
    else
      campaign_url(comment.commented.campaign, :anchor => "comment_#{comment.id}")
    end
  end

  def pte_link(pte)
    link_to(pte.name, pte.wikipedia_url, :target => '_blank')
  end

  def responsible_name_type(location)
    if location.pte_responsible?
      responsible = location.passenger_transport_executive.name
    else
      responsible = "#{t('shared.problem.the')} #{t(location.responsible_organization_type)}"
    end
  end

  def location_path(location)
    if location.is_a? Stop
      return stop_path(location.locality, location)
    elsif location.is_a? StopArea
      if StopAreaType.station_types.include?(location.area_type)
         return station_path(location.locality, location)
       elsif StopAreaType.ferry_terminal_types.include?(location.area_type)
         return ferry_terminal_path(location.locality, location)
       else
         return stop_area_path(location.locality, location)
      end
    elsif location.is_a? Route
      return route_path(location.region, location)
    elsif location.is_a? SubRoute
      return sub_route_path(location, attributes)
    end
    raise "Unknown location type: #{location.class}"
  end

  def location_url(location, attributes={})
   if location.is_a? Stop
     return stop_url(location.locality, location, attributes)
   elsif location.is_a? StopArea
     if StopAreaType.station_types.include?(location.area_type)
       return station_url(location.locality, location, attributes)
     elsif StopAreaType.bus_station_types.include?(location.area_type)
       return bus_station_url(location.locality, location, attributes)
     elsif StopAreaType.ferry_terminal_types.include?(location.area_type)
       return ferry_terminal_url(location.locality, location, attributes)
     else
       return stop_area_url(location.locality, location, attributes)
     end
   elsif location.is_a? Route
     return route_url(location.region, location, attributes)
   elsif location.is_a? SubRoute
     return sub_route_url(location, attributes)
   end
   raise "Unknown location type: #{location.class}"
  end

  def admin_location_url(location)
    if location.is_a? Stop
      return admin_url(stop_path(location.id))
    elsif location.is_a? StopArea
      return admin_url(stop_area_path(location.id))
    elsif location.is_a? Route
      return admin_url(route_path(location.id))
    end
  end

  def add_comment_url(commentable)
    if commentable.is_a?(Campaign)
      return add_comment_campaign_url(commentable)
    elsif commentable.is_a?(Problem)
      return add_comment_problem_url(commentable)
    else
      raise "Unhandled commentable type in add_comment_url: #{commentable.type}"
    end
  end

  def commented_url(commentable)
    if commentable.is_a?(Campaign)
      return campaign_url(commentable)
    elsif commentable.is_a?(Problem)
      return problem_url(commentable)
    else
      raise "Unhandled commentable type in commentable_url: #{commentable.type}"
    end
  end

  def map_link_url(location, link_type)
    if link_type == :location
      return location_url(location)
    elsif link_type == :problem
      return new_problem_url(:location_id => location.id, :location_type => location.class)
    else
      raise "Unknown link_type in map_link_url: #{link_type}"
    end
  end

  def short_date(date)
    return date.strftime("%e %b %Y").strip
  end

  def update_text(update, link)
    extra_parts = []
    if update.incoming_message
      extra_parts << t('campaign_mailer.update.in_response_to', :subject => update.incoming_message.subject)
      if !update.incoming_message.from.blank?
        extra_parts << t('campaign_mailer.update.received_from', :from => update.incoming_message.from)
      end
    end
    if update.outgoing_message
      extra_parts << t('campaign_mailer.update.about_email', :name => update.outgoing_message.recipient_name)
      extra_parts << t('campaign_mailer.update.with_subject', :subject => update.outgoing_message.subject)
    end
    if extra_parts.empty?
      extra = ''
    else
      extra = " " + extra_parts.join(" ")
    end
    text = t('campaign_mailer.update.new_update', :name => update.user.name,
                                                  :title => update.campaign.title,
                                                  :link => link, :extra => extra)
  end


  def national_route_link(region, national_region, anchor)
    if @region != @national_region
      national_link =  link_to(t('locations.show_route_region.national_routes'), route_region_path(@national_region, :anchor => anchor))
      return t('locations.show_route_region.see_also_national_routes', :national => national_link)
    else
      return ''
    end
  end

  def campaign_display_status(campaign)
    case campaign.status
    when :confirmed
      'current'
    else
      campaign.status.to_s
    end
  end

  def twitter_url(campaign)
    if current_user == campaign.initiator
      text = campaign.call_to_action
    else
      text = campaign.supporter_call_to_action
    end
    twitter_params = { :url => campaign_url(campaign),
                       :text => text,
                       :via => 'FixMyTransport' }
    return "http://twitter.com/share?#{twitter_params.to_query}"
  end
  
  def facebook_url(campaign)
    "http://www.facebook.com"
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    link_to title, admin_url(url_for(params.merge({:sort => column, :direction => direction}))), {:class => css_class}
  end
  
  def assignment_title(assignment)
    case assignment.task_type
    when 'find_transport_organization'
      return t('campaigns.show.find_operator_task_title')
    when 'find_transport_organization_contact_details'
      return t('campaigns.show.find_contact_task_title')
    else
      raise "No title set for assignment type #{assignment.task_type}"
    end
  end
  
  def assignment_details(assignment)
    case assignment.task_type
    when 'find_transport_organization'
      return t('campaigns.show.find_operator_task_description', :location => readable_location_type(assignment.campaign.location))
    when 'find_transport_organization_contact_details'
      return t('campaigns.show.find_contact_task_description', :name => assignment.problem.operator.name)
    else 
      raise "No details set for assignment type #{assignment.task_type}"
    end
  end
    
  def assignment_icon(assignment)
    case assignment.task_type
    when 'find_transport_organization'
      return 'person'
    when 'find_transport_organization_contact_details'
      return 'person'
    else
      raise "No icon set for assignment type #{assignment.task_type}"
    end
  end
  
  def contact_description(contact_type, campaign)
    case contact_type
    when 'OperatorContact'
      return t('campaigns.show.contact_operator', :location => MySociety::Format.ucfirst(readable_location_type(campaign.location)))
    when 'CouncilContact'
      return t('campaigns.show.contact_council')
    when 'PassengerTransportExecutive'
      return t('campaigns.show.contact_passenger_transport_executive')
    else
      raise "No contact description set for contact_type #{contact_type}"
    end
      
  end
  
end
