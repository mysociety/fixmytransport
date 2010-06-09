class Gazetteer 

  def self.postcode_from_area(attributes)
    if MySociety::Validate.is_valid_postcode(attributes[:area])
      attributes[:postcode] = attributes[:area]
      attributes[:area] = nil
    end
  end

  def self.find_stops_from_attributes(attributes, limit=nil)
    self.postcode_from_area(attributes) if !attributes[:area].blank?
    stop_type_codes = StopType.codes_for_transport_mode(attributes[:transport_mode_id])
    query = 'stop_type in (?)'
    params = [stop_type_codes]
    order = nil
    includes = nil
    if !attributes[:postcode].blank?
      coord_info = MySociety::MaPit.get_location(attributes[:postcode])
      easting, northing = coord_info['easting'], coord_info['northing']
      query += " AND ST_Distance(
                ST_GeomFromText('POINT(#{easting} #{northing})', #{BRITISH_NATIONAL_GRID}), 
                stops.coords) < 1000"
    end
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
    if !attributes[:route_number].blank?
      routes = find_routes_from_attributes(attributes)
      query += ' AND route_segments.route_id in (?)'
      params << routes
      includes = :route_segments
    end
    conditions = [query] + params
    stops = Stop.find(:all, :conditions => conditions, 
                            :limit => limit, 
                            :order => order, 
                            :include => includes)
    stops
  end
  
  def self.find_routes_from_attributes(attributes, limit=nil)
    self.postcode_from_area(attributes) if !attributes[:area].blank?
    routes = Route.find_from_attributes(attributes, limit)
    return routes if ! routes.empty?    
    select_clause = 'SELECT distinct routes.*'
    from_clause = 'FROM routes'
    where_clause = 'WHERE transport_mode_id = ?'
    params = [attributes[:transport_mode_id]]
    localities = []
    if !attributes[:area].blank?
      localities = Locality.find_all_with_descendants(attributes[:area])
    end
    if !attributes[:postcode].blank?
      coord_info = MySociety::MaPit.get_location(attributes[:postcode])
      easting, northing = coord_info['easting'], coord_info['northing']
      localities = Locality.find_by_coordinates(easting, northing)
    end
    if !localities.empty?
      from_clause += ", route_localities"
      where_clause += " AND route_localities.route_id = routes.id
                        AND route_localities.locality_id in (?)"
      params << localities
    end
    if !attributes[:route_number].blank?
      route_number = attributes[:route_number].downcase
      where_clause += " AND (lower(routes.number) = ? OR lower(routes.name) = ?)"
      params << route_number
      params << route_number
    end
    if limit 
      where_clause += " limit #{limit}"
    end
    params = ["#{select_clause} #{from_clause} #{where_clause}"] + params
    routes = Route.find_by_sql(params)
    routes
  end

end