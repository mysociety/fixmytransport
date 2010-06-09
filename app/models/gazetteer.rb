class Gazetteer 
  
  def self.postcode_from_area(attributes)
    if MySociety::Validate.is_valid_postcode(attributes[:area])
      attributes[:postcode] = attributes[:area]
      attributes[:area] = nil
    end
  end
  
  def self.coords_from_postcode(postcode)
    begin
      coord_info = MySociety::MaPit.get_location(postcode)
    rescue MySociety::RABX::RABXError
      return :postcode_not_found
    end
    return coord_info
  end
  
  # accepts attributes
  # - name - stop name
  # - area - town/area
  # - transport_mode_id
  # - route_number - route number/name
  # options 
  # - limit - Number of results to return
  # - stops_only - Don't return stop areas
  def self.find_stops_from_attributes(attributes, options={})
    errors = []
    stops = []
    self.postcode_from_area(attributes) if !attributes[:area].blank?
    stop_type_codes = StopType.codes_for_transport_mode(attributes[:transport_mode_id])
    query = 'stop_type in (?)'
    params = [stop_type_codes]
    includes = nil
    if !attributes[:postcode].blank?
      coord_info = coords_from_postcode(attributes[:postcode])
      if coord_info == :postcode_not_found
        errors << :postcode_not_found
      else
        query += " AND ST_Distance(
                  ST_GeomFromText('POINT(#{coord_info['easting']} #{coord_info['northing']})', 
                  #{BRITISH_NATIONAL_GRID}), 
                  stops.coords) < 1000"
      end
    end
    if !attributes[:area].blank?
      localities = Locality.find_all_with_descendants(attributes[:area])
      if localities.empty?
        errors << :area_not_found
      else
        query += ' AND locality_id in (?)'
        params << localities
      end
    end
    if !attributes[:name].blank? 
      name = attributes[:name].downcase
      query += ' AND (lower(common_name) like ? OR lower(street) = ? OR naptan_code = ?)'
      params <<  "%#{name}%"
      params << name
      params << name
    end
    if !attributes[:route_number].blank?
      route_results = find_routes_from_attributes(attributes)
      errors += route_results[:errors]
      if !route_results[:results].empty?
        query += ' AND route_segments.route_id in (?)'
        params << route_results[:results]
        includes = :route_segments_as_from_stop, :route_segments_as_to_stop
      end
    end
    conditions = [query] + params
    if errors.empty? 
      stops = Stop.find(:all, :conditions => conditions, 
                              :limit => options[:limit], 
                              :include => includes)
    end
    if !options[:stops_only] and stops.size > 1 
      stop_area = Stop.common_area(stops, attributes[:transport_mode_id])
      stops = [stop_area] if stop_area
    end
    { :results => stops, :errors => errors.uniq }
  end
  
  # accepts 
  # - name - stop name
  # - area - town/area
  # - transport_mode_id
  # - route_number - route number/name
  # options 
  # - limit - Number of results to return
  def self.find_routes_from_attributes(attributes, options={})
    errors = []
    routes = []
    self.postcode_from_area(attributes) if !attributes[:area].blank?
    # finding by stop names 
    routes = Route.find_from_attributes(attributes, limit=options[:limit])
    return {:results => routes, :errors => errors } if ! routes.empty?    
    
    select_clause = 'SELECT distinct routes.*'
    from_clause = 'FROM routes'
    where_clause = 'WHERE transport_mode_id = ?'
    params = [attributes[:transport_mode_id]]
    localities = []
    if !attributes[:area].blank?
      localities = Locality.find_all_with_descendants(attributes[:area])
      if localities.empty?
        errors << :area_not_found
      end
    end
    if !attributes[:postcode].blank?
      coord_info = coords_from_postcode(attributes[:postcode])
      if coord_info == :postcode_not_found
        errors << :postcode_not_found
      else
        localities = Locality.find_by_coordinates(coord_info['easting'], coord_info['northing'])
      end
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
      where_clause += " limit #{options[:limit]}"
    end
    params = ["#{select_clause} #{from_clause} #{where_clause}"] + params
    if errors.empty?
      routes = Route.find_by_sql(params)
    end
    { :results => routes, :errors => errors }
  end

end