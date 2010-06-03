class Gazetteer 

  def self.find_stops_from_attributes(attributes, limit=nil)
    return [] if attributes[:area].blank?
    stop_type_codes = StopType.codes_for_transport_mode(attributes[:transport_mode_id])
    localities = Locality.find_all_with_descendants(attributes[:area])
    query = 'locality_id in (?) AND stop_type in (?)'
    params = [localities, stop_type_codes]
    if !attributes[:name].blank? 
      name = attributes[:name].downcase
      query += ' AND (lower(common_name) like ? OR lower(street) = ? OR naptan_code = ?)'
      params <<  "%#{name}%"
      params << name
      params << name
    end
    conditions = [query] + params
    stops = Stop.find(:all, :conditions => conditions, :limit => limit)
    stops
  end
  
  def self.find_routes_from_attributes(attributes, limit=nil)
    localities = Locality.find_all_with_descendants(attributes[:area])
    routes = Route.find_all_by_transport_mode_id(attributes[:transport_mode_id], 
                                                 route_number=attributes[:route_number], 
                                                 localities=localities, 
                                                 limit=limit)
    routes
  end
  
end