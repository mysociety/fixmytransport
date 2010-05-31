class Gazetteer 

  def self.find_stops_from_attributes(attributes, limit=nil)
    return [] if attributes[:area].blank?
    stop_type_codes = StopType.codes_for_transport_mode(attributes[:transport_mode_id])
    localities = Locality.find_all_with_descendants(attributes[:area])
    stops = Stop.find(:all, :conditions => ['locality_id in (?) and stop_type in (?)', 
                            localities, stop_type_codes], :limit => limit)
    stops
  end
  
  def self.find_routes_from_attributes(attributes, limit=nil)
    return [] if attributes[:area].blank?
    stop_type_codes = StopType.codes_for_transport_mode(attributes[:transport_mode_id])
    localities = Locality.find_all_with_descendants(attributes[:area])
    routes = Route.find(:all, :conditions => ['stops.locality_id in (?) and stops.stop_type in (?)',
                                              localities, stop_type_codes], 
                              :include => {:route_segments => [:from_stop, :to_stop]}, 
                              :limit => limit)
    routes
  end
  
end