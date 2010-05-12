module Admin::LocationSearchesHelper

  def render_event event
    case event[:type]
    when :result
      text = "Showed result #{location_link(event[:location])}" 
    when :response
      text = "Result #{location_link(event[:location])} was #{event[:response] == :success ? "correct" : "not correct"}"
    when :method
      text = "Got result set using #{event[:method]}"
    when :choice
      text = "Showed a choice of #{event[:locations]} locations" 
    end
    return text
  end
  
  def location_link location_info
    location = location_info[:class].constantize.find(location_info[:id])
    link_to(location.name, main_url(location_path(location)))
  end
  
end