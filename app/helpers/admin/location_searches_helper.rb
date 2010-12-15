module Admin::LocationSearchesHelper

  def render_event event
    case event[:type]
    when :result
      if event[:result] == :failure
        text = "Failed to find results"
      else
        text = "Showed result #{location_link(event[:location])}" 
      end
    when :method
      text = "Got result set using #{event[:method]}"
    when :choice
      if event[:location_type]
        things = event[:location_type]
      else
        things = 'locations'
      end
      text = "Showed a choice of #{event[:locations]} #{things}" 
    end
    return text
  end
  
  def location_link location_info
    location = location_info[:class].constantize.find(location_info[:id])
    link_to(location.name, main_url(location_path(location)))
  end
  
end