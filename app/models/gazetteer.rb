class Gazetteer 
  
  def self.find_stops_from_attributes(attributes)
    stop_type_codes = StopType.codes_for_transport_mode(attributes[:transport_mode_id])
    return [] if attributes[:area].blank?
    localities = Locality.find_all_by_name(attributes[:area])
    stops = Stop.find(:all, :conditions => ['locality_id in (?) and stop_type in (?)', 
                            localities, stop_type_codes])
    stops
  end
  
  def self.find_routes_from_attributes(attributes)
    stops = find_stops_from_attributes(attributes)
    routes = stops.map{ |stop| stop.routes }.flatten.uniq
    routes
  end
  
end