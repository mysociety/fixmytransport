class Gazetteer 

  def self.find_stops_from_attributes(attributes, limit=nil)
    stop_type_codes = StopType.codes_for_transport_mode(attributes[:transport_mode_id])
    query = 'stop_type in (?)'
    params = [stop_type_codes]
    if !attributes[:area].blank?
      localities = Locality.find_all_with_descendants(attributes[:area])
      query += ' AND locality_id in (?)'
      params << localities
    end
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
    localities = []
    if !attributes[:area].blank?
      localities = Locality.find_all_with_descendants(attributes[:area])
    end
    routes = Route.find_all_by_transport_mode_id(attributes[:transport_mode_id], 
                                                 route_number=attributes[:route_number], 
                                                 localities=localities, 
                                                 limit=limit)
    routes
  end
  

end