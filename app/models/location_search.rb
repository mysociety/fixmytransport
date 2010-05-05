class LocationSearch < ActiveRecord::Base
  
  serialize :events
  
  def self.find_current(session_id)
    find(:first, :conditions => ['session_id = ? and active = ?', session_id, true], 
                 :order => 'created_at desc')
  end
  
  def self.close_session_searches(session_id)
    searches = find(:all, :conditions => ['session_id = ? and active = ?', session_id, true])
    searches.each { |search| search.toggle!(:active) }
  end
  
  def self.new_search!(session_id, params)
    close_session_searches(session_id)
    attributes = params[:problem][:location_attributes]
    attributes[:transport_mode_id] = params[:problem][:transport_mode_id]
    attributes[:location_type] = params[:problem][:location_type]
    attributes[:session_id] = session_id
    attributes[:active] = true
    attributes[:events] = []
    self.create!(attributes)
  end
  
  def add_choice(locations)
    location_list = locations.map{ |location| identifying_info(location) }
    self.events << { :type => :choice, 
                     :locations => location_list } 
    save
  end
  
  def add_location(location)
    self.events << { :type => :result, 
                     :location => identifying_info(location) }
    save
  end
  
  def add_response(location, response)
    response = 'invalid' unless ['success', 'fail'].include? response
    response = response.to_sym
    self.events << { :type => :response, 
                     :location => identifying_info(location),
                     :response => response }
    save
    close if response == :success
  end
  
  def responded?(location)
    if self.events.detect{ |event| event[:type] == :response && event_about_location?(event, location) }
      return true
    else
      return false
    end
  end
  
  def event_about_location?(event, location)
    return true if event[:location] == identifying_info(location)
    return false 
  end
  
  def close
    LocationSearch.close_session_searches(session_id)
  end
  
  def identifying_info(location)
    { :id => location.id, :class => location.class.to_s }
  end
  
end
