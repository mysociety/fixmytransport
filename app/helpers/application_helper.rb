# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Do we have content stored up for a yield of a particular name?
  # Rough backport of method built-in to Rails in later versions
  def content_for?(name)
    ivar = "@content_for_#{name}"
    !instance_variable_get(ivar).nil?
  end

  def google_maps_key
    MySociety::Config.get('GOOGLE_MAPS_API_KEY', '')
  end

  def minify(filelist)
    if !MySociety::Config.getbool('STAGING_SITE', true)
      filelist = filelist.map{ |filename| "#{filename}.min" }
    end
    filelist
  end

  def library_js_link
    minified_js_files = ['jquery-1.5.2.min',
                         'jquery-ui-1.8.13.custom.min',
                         'jquery.autofill.min',
                         'jquery.form.min',
                         'OpenLayers']
    js_files = ['map']
    files = minified_js_files + minify(js_files)
    javascript_include_tag(files, :charset => 'utf-8', :cache => 'libraries')
  end

  def admin_library_js_link
    minified_js_files = ['jquery-1.5.2.min',
                         'jquery-ui-1.8.13.custom.min',
                         'admin/OpenLayers']
    js_files = ['map', 'admin']
    files = minified_js_files + minify(js_files)
    javascript_include_tag(files, :charset => 'utf-8', :cache => 'admin_libraries')
  end

  def main_js_link
    js_files = ['fixmytransport', 'fb']
    javascript_include_tag(minify(js_files), :charset => 'utf-8', :cache => 'main')
  end

  def main_style_link
    minified_css_files = ['/javascripts/theme/default/style.tidy.css']
    css_files = ['core', 'map', 'buttons', 'ui-tabs-mod', 'fixmytransport', 'guides' ]
    files = minified_css_files + minify(css_files)
    stylesheet_link_tag(files, :cache => 'main')
  end

  # options:
  #  no_jquery - don't include a tag for the main jquery js file
  def map_javascript_include_tags(options={})
    tags = []
    tags << "<script src=\"http://maps.google.com/maps?file=api&amp;v=2&amp;sensor=false&amp;key=#{google_maps_key}\" type=\"text/javascript\"></script>"
    tags.join("\n")
  end

  # if the request has params that will determine map display (usually means javascript is not enabled)
  # then regenerate the content and don't cache. Otherwise, save new content to cache, and allow existing
  # cache to be used.
  def cache_unless_map_params(cache_options)
    if params[:lat] or params[:lon] or params[:zoom]
      yield
    else
      cache(cache_options) do
        yield
      end
    end
  end

  def icon_style(location, center_y, center_offset_y, center_x, center_offset_x, zoom)
    top = Map.lat_to_y_offset(center_y, center_offset_y, location[:lat], zoom) - location[:height]
    left = Map.lon_to_x_offset(center_x, center_offset_x, location[:lon], zoom) - (location[:width] / 2)
    "position: absolute; top: #{top}px; left: #{left}px;"
  end

  def icon_height(small)
    small ? SMALL_ICON_HEIGHT : LARGE_ICON_HEIGHT
  end

  def icon_width(small)
    small ? SMALL_ICON_WIDTH : LARGE_ICON_WIDTH
  end

  def js_translation_list(keys)
      keys.map {|k| "'#{k}': \"#{I18n.translate(k)}\""}.join(",\n        ")
  end

  # Generate a hash of data used to render the point on a map
  # Required options:
  # :link_type - [:problem|:location] - link stop to problem reporting
  # url or location url
  # :highlight - is this point to be rendered prominently
  # :small - should a small marker be used
  # Other options
  # :line_only - just return enough data for a line map
  # :location - generate the description and link for the location
  # passed, not for the stop itself.
  def point_coords(stop, options)
    location = (options[:location] or stop)
    if options[:line_only]
      data = { :lat => stop.lat,
               :lon => stop.lon,
               :id => "#{stop.class}_#{stop.id}" }
    else
      data = { :lat => stop.lat,
               :lon => stop.lon,
               :id => "#{stop.class}_#{stop.id}",
               :url => map_link_path(location, options[:link_type]),
               :description => location.description,
               :highlight => location.highlighted == true,
               :icon => stop_icon(stop, options[:small], options[:highlight]),
               :height => icon_height(options[:small]),
               :width => icon_width(options[:small]) }
    end
    return data
  end

  def stop_icon(location, small=false, highlight=nil)
    if highlight == :has_content
      background = ! location.highlighted == true
    else
      background = false
    end
    name = '/images/map-icons/map-'
    if location.is_a?(Route) || location.is_a?(SubRoute)
      if location.is_a?(SubRoute) || location.transport_mode_name == 'Train'
        name += 'train-'
        name += background ? 'grey' : 'blue'
      elsif location.transport_mode_name == 'Tram/Metro'
        name += 'tram-'
        name += background ? 'grey' : 'green'
      elsif location.transport_mode_name == 'Ferry'
        name += 'boat-'
        name += background ? 'grey' : 'orange'
      else
        name += 'bus-'
        name += background ? 'grey' : 'magenta'
      end
    else
      if location.respond_to?(:area_type) && location.area_type == 'GRLS'
        name += 'train-'
        name += background ? 'grey' : 'blue'
      elsif location.respond_to?(:area_type) && location.area_type == 'GTMU'
        name += 'tram-'
        name += background ? 'grey' : 'green'
      elsif location.respond_to?(:area_type) && location.area_type == 'GFTD'
        name += 'boat-'
        name += background ? 'grey' : 'orange'
      else
        name += 'bus-'
        name += background ? 'grey' : 'magenta'
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
    stop_options = {:small => true, :link_type => :location, :line_only => line_only}
    segments_js = route.journey_patterns.map{ |jp| jp.route_segments }.flatten.map do |segment|
      [point_coords(segment.from_stop, stop_options),
       point_coords(segment.to_stop, stop_options), segment.id]
    end
    segments_js.to_json
  end

  def location_stops_coords(locations, small, link_type, highlight=nil)
    array_content = []
    locations.each do |location|
      if location.is_a? Route or location.is_a? SubRoute
        if location.show_as_point || highlight
          array_content << point_coords(location, { :small => highlight ? small : true,
                                                   :link_type => link_type,
                                                   :highlight => highlight })
        elsif location.is_a? Route and link_type == :problem
          array_content <<  location.points.map{ |stop| point_coords(stop, { :small => true,
                                                                             :link_type => link_type,
                                                                             :location => location,
                                                                             :highlight => highlight })}
        else
          array_content <<  location.points.map{ |stop| point_coords(stop, { :small => true,
                                                                             :link_type => link_type,
                                                                             :highlight => highlight })}
        end
      else
       array_content << point_coords(location, { :small => small,
                                                 :link_type => link_type,
                                                 :highlight => highlight })
      end
    end
    array_content
  end

  def stop_name_for_admin(stop)
    name = stop.full_name
    if ! stop.street.blank?
      name += " #{t('admin.on_street', :street => stop.street)}"
    end
    name += " #{t('admin.in_locality', :locality => stop.locality_name)} (#{stop.id})"
    name
  end

  def external_search_link(text)
    "http://www.google.co.uk/search?ie=UTF-8&q=#{CGI.escape(text)}"
  end

  def on_or_at_the(location)
    if location.is_a? Route or location.is_a? SubRoute
      return t('shared.problem.on_the')
    elsif location.is_a?(StopArea) && ['GRLS', 'GTMU', 'GFTD'].include?(location.area_type)
      return t('shared.problem.at')
    else
      return t('shared.problem.at_the')
    end
  end

  def at_the_location(location)
    location_string = location.name
    location_string.gsub!(/^Train route/, 'train route')
    location_string.gsub!(/^Number /, 'number ')

    location_string = "#{on_or_at_the(location)} #{location_string}"
    if location.is_a?(Stop) && location.transport_mode_names.include?('Bus')
      location_string += " bus stop"
    end
    location_string
  end

  def readable_location_type(location)
    if location.is_a? Stop or location.is_a? StopArea

      if location.is_a?(StopArea)
        if location.area_type == 'GBCS'
          return 'bus station'
        end
      end
      transport_mode_names = location.transport_mode_names
      if transport_mode_names.include?('Train') or transport_mode_names == ['Tram/Metro']
        return "station"
      end
      if transport_mode_names.include?('Ferry')
        return 'terminal'
      end
      if transport_mode_names.include?('Bus')
        return "bus stop"
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

  def name_in_sentence(location)
    if location.is_a?(TrainRoute) || location.is_a?(SubRoute)
      return location.name[0, 1].downcase + location.name[1..-1]
    else
      return location.name
    end
  end

  # Construct an explanation string saying why you might want to report a problem 
  # at this location
  def location_explanation(location)
    orgs = @template.org_names(location.responsible_organizations, t('problems.new.or'),
                               wrapper_start="", wrapper_end="")
    if !orgs.strip.blank?
      orgs = " " + t('shared.location_content.to') + " " + orgs
    end
    explanation_params = {:orgs => orgs}
    explanation_string = case location
    when Stop
      'shared.location_content.stop_explanation'
    when StopArea
      'shared.location_content.station_explanation'
    when TrainRoute, SubRoute
      'shared.location_content.train_route_explanation'
    when TramMetroRoute
      'shared.location_content.metro_route_explanation'
    when FerryRoute
      'shared.location_content.ferry_route_explanation'
    else
      'shared.location_content.bus_route_explanation'
    end
    t(explanation_string, :orgs => orgs, :location => readable_location_type(location))
  end


  def org_names(orgs, connector, wrapper_start='<strong>', wrapper_end='</strong>')
    names = orgs.map{ |org| "#{wrapper_start}#{org.name}#{wrapper_end}" }
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

  def issue_url(issue)
    if issue.is_a? Campaign
      return campaign_url(issue)
    else
      return problem_url(issue)
    end
  end

  def location_path(location, attributes={})
    if location.is_a? Stop
      return stop_path(location.locality, location, attributes)
    elsif location.is_a? StopArea
      if StopAreaType.station_types.include?(location.area_type)
         return station_path(location.locality, location, attributes)
       elsif StopAreaType.ferry_terminal_types.include?(location.area_type)
         return ferry_terminal_path(location.locality, location, attributes)
       elsif StopAreaType.bus_station_types.include?(location.area_type)
         return bus_station_path(location.locality, location, attributes)
       else
         return stop_area_path(location.locality, location, attributes)
      end
    elsif location.is_a? Route
      return route_path(location.region, location, attributes)
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
    if location.is_a?(Stop)
      return admin_url(admin_stop_path(location.id))
    elsif location.is_a?(StopArea)
      return admin_url(admin_stop_area_path(location.id))
    elsif location.is_a?(Route)
      return admin_url(admin_route_path(location.id))
    end
  end

  def admin_contact_url(contact)
    case contact
    when PassengerTransportExecutiveContact
      return admin_url(admin_pte_contact_path(contact.id))
    when OperatorContact
      return admin_url(admin_operator_contact_path(contact.id))
    when CouncilContact
      return admin_url(admin_council_contact_path(contact.id))
    end
  end

  def admin_organization_url(organization)
    if organization.is_a?(Operator)
      return admin_url(admin_operator_path(organization.id))
    elsif organization.is_a?(Council)
      return admin_url(admin_council_contacts_path(:area_id => organization.id))
    elsif organization.is_a?(PassengerTransportExecutive)
      return admin_url(admin_pte_path(organization.id))
    end
  end

  def admin_star_html(want_display, star_type=:administrator)
    if want_display
      if star_type == :expert
        star_html = '&#9734;'
        title = t('admin.user_role_expert')
      else
        star_html = '&#9733;'
        title = t('admin.user_role_admin')
      end
      return "<span class='admin-star' title='#{title}'>#{star_html}</span>"
    end
  end

  def add_comment_url(commentable)
    case commentable
    when Campaign
      return add_comment_campaign_url(commentable)
    when Problem
      return add_comment_problem_url(commentable)
    when Route
      return add_comment_route_url(commentable.region, commentable)
    when Stop
      return add_comment_stop_url(commentable.locality, commentable)
    when StopArea
      if StopAreaType.station_types.include?(commentable.area_type)
         return add_comment_station_url(commentable.locality, commentable)
       elsif StopAreaType.bus_station_types.include?(commentable.area_type)
         return add_comment_bus_station_url(commentable.locality, commentable)
       elsif StopAreaType.ferry_terminal_types.include?(commentable.area_type)
         return add_comment_ferry_terminal_url(commentable.locality, commentable)
       else
         return add_comment_stop_area_url(commentable.locality, commentable)
       end
    when SubRoute
      return add_comment_sub_route_url(commentable)
    else
      raise "Unhandled commentable type in add_comment_url: #{commentable.class}"
    end
  end

  def commented_url(commentable)
    case commentable
    when Campaign
      return campaign_url(commentable)
    when Problem
      return problem_url(commentable)
    when Route, Stop, StopArea, SubRoute
      return location_url(commentable)
    else
      raise "Unhandled commentable type in commentable_url: #{commentable.class.to_s}"
    end
  end

  # sort the stations to the beginning of a list of stations and stops (otherwise
  # keep the order stable)
  def sort_stations(locations)
    stations, stops = locations.partition{ |location| location.is_a?(StopArea) }
    return stations + stops
  end

  def comment_header(comment)
    text = ''
    if comment.commented.is_a?(Campaign)
      text = t('campaigns.show.user_says', :name => h(comment.user.name))
    elsif comment.commented.is_a?(Problem)
      text = t('problems.show.user_says', :name => h(comment.user.name))
    else
      text = t('shared.location_content.user_says', :name => h(comment.user.name))
    end
    if comment.mark_fixed?
      text += " " + t('problems.show.marked_as_fixed')
    end
    text
  end

  def map_link_path(location, link_type)
    if link_type == :location
      return location_path(location, :escape => false)
    elsif link_type == :problem
      return existing_problems_path({:location_id => location.id, :location_type => location.class, :escape => false})
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

  def issue_list_image_url(issue)
    icon_path = '/images/transport-icons/'
    if issue.is_a?(Campaign)
      image_prefix = 'cam-'
    else
      image_prefix = 'rep-'
    end
    if issue.is_a?(Campaign) && !issue.campaign_photos.empty?
      return issue.campaign_photos.first.image.url(:list)
    end
    image_start = "#{icon_path}#{image_prefix}"
    if issue.location.is_a?(Route) or issue.location.is_a?(SubRoute)
      transport_mode = issue.location.transport_mode.name
      case transport_mode
      when 'Train'
        return "#{image_start}train.jpg"
      when 'Tram/Metro'
        return "#{image_start}tram.jpg"
      when 'Ferry'
        return "#{image_start}ferry.jpg"
      else
        return "#{image_start}bus.jpg"
      end
    else
      if issue.location.respond_to?(:area_type)
        case issue.location.area_type
        when 'GRLS'
          return "#{image_start}train.jpg"
        when 'GTMU'
          return "#{image_start}tram.jpg"
        when 'GFTD'
          return "#{image_start}ferry.jpg"
        else
          return "#{image_start}bus.jpg"
        end
      else
        return "#{image_start}bus.jpg"
      end
    end
  end

  def problem_display_status(problem)
    case problem.status
    when :confirmed
      'current'
    else
      problem.status.to_s
    end
  end

  def twitter_url(campaign)
    if current_user == campaign.initiator
      text = campaign.twitter_call_to_action
    else
      text = campaign.supporter_call_to_action
    end
    twitter_params = { :url => campaign_url(campaign),
                       :text => text,
                       :via => 'FixMyTransport' }
    return "http://twitter.com/share?#{twitter_params.to_query}"
  end

  def facebook_description(campaign, user)
    return '' if ! user
    if user == campaign.initiator
      text = t("campaigns.show.initiator_facebook_description")
    else
      text = t('campaigns.show.supporter_facebook_description')
    end
    return text
  end

  def facebook_message(campaign, user)
    return '' if ! user
    if user == campaign.initiator
      text = t("campaigns.show.initiator_facebook_message", :title => campaign.title, :org => campaign.responsible_org_descriptor)
    else
      text = t("campaigns.show.supporter_facebook_message", :title => campaign.title, :org => campaign.responsible_org_descriptor)
    end
    return text
  end

  def sortable(column, title = nil, allow_sort=true)
    title ||= column.titleize
    if allow_sort
      css_class = column == sort_column ? "current #{sort_direction}" : nil
      direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
      link_to title, admin_url(url_for(params.merge({:sort => column, :direction => direction}))), {:class => css_class}
    else
      title
    end
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
      names = assignment.problem.responsible_organizations.map{ |org| org.name }.to_sentence
      return t('campaigns.show.find_contact_task_description', :name => names)
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
    when 'PassengerTransportExecutiveContact'
      return t('campaigns.show.contact_passenger_transport_executive')
    else
      raise "No contact description set for contact_type #{contact_type}"
    end
  end

  def problem_sending_history(problem)
    history = ''
    dates_hash = Hash.new{ |hash, key| hash[key] = [] }
	  problem.reports_sent.each do |sent_email|
	    dates_hash[sent_email.created_at.to_date] << sent_email.recipient.name
	  end
	  dates_hash.to_a.sort.each do |date, recipients|
	    history_text = t('problems.show.sent_time', :date => date.to_s(:short),
	                                                :recipient => recipients.uniq.to_sentence)
	    history += "<li>#{history_text}</li>"
	  end
		history
  end

  # Operator links for the campaign and problem pages - if the problem was on a sub route,
  # and the user chose an operator, just show that.
  # If not, but the location has operators (and there aren't too many to display nicely),
  # show those
  def problem_operator_links(problem)
    location = problem.location
    if location.is_a?(SubRoute) && location.route_operators.empty? && problem.responsible_operators.size == 1
      return t('shared.operator_links.operated_by', :operators => operator_links(problem.responsible_operators))
    elsif location.respond_to?(:operators) && !location.operators.empty? && location.operators.size <= 2
	    return t('shared.operator_links.operated_by', :operators => operator_links(location.operators))
	  else
	    return nil
    end
  end

  def role_flags(user)
    flags = []
    if user.is_expert? or user.is_admin?
      flags << '<div class="user-flags">'
    end
    if user.is_expert?
      flags << "<div class=\"user-flag flag-expert\"><abbr title=\"#{t('shared.user_flags.expert_explanation')}\">#{t('shared.user_flags.expert')}</abbr></div>"
    end
    if user.is_admin?
      flags << "<div class=\"user-flag flag-admin\"><abbr title=\"#{t('shared.user_flags.admin_explanation')}\">#{t('shared.user_flags.admin')}</abbr></div>"
    end
    if user.is_expert? or user.is_admin?
      flags << '</div>'
    end
    flags.join(" ")
  end

  # Return a cleaned-up hash of changed attributes for two models (or two versions of a model)
  # Hash is of the form { attribute_name => [old_value, new_value] }
  def change_hash(new_model, old_model)
    change_hash = old_model.diff(new_model)
    # replace status code with the friendlier status
    if change_hash.has_key?(:status_code) and new_model.class.respond_to?(:status_code_to_symbol)
      values = change_hash.delete(:status_code)
      change_hash[:status] = values.map do |status_code|
        new_model.class.status_code_to_symbol[status_code.to_i]
      end
    end
    return change_hash
  end

  def experiment_start(name)
    if MySociety::Config.get("DOMAIN", '127.0.0.1:3000') == 'www.fixmytransport.com'
      "<script>utmx_section(\"#{name}\")</script>"
    else
      ""
    end
  end

  def experiment_end
    if MySociety::Config.get("DOMAIN", '127.0.0.1:3000') == 'www.fixmytransport.com'
      "</noscript>"
    else
      ""
    end
  end

end
