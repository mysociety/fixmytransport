class Gazetteer 
  
  def self.postcode_from_area(attributes)
    attributes[:area] = attributes[:area].strip
    if MySociety::Validate.is_valid_postcode(attributes[:area]) || 
      MySociety::Validate.is_valid_partial_postcode(attributes[:area])
      attributes[:postcode] = attributes[:area]
      attributes[:area] = nil
    end
  end
  
  def self.coords_from_postcode(postcode)
    postcode = postcode.gsub(/\s/, '')
    if MySociety::Validate.is_valid_postcode(postcode)
      return MySociety::MaPit.call('postcode', postcode)
    elsif MySociety::Validate.is_valid_partial_postcode(postcode)
      return MySociety::MaPit.call('postcode', "partial/#{postcode}")
    end
    return :not_postcode
  end
  
  # Accepts a name, full or partial postcode. Will return a hash of coord info about a postcode,
  # if a full or partial postcode is passed.
  # Otherwise, a list of localities matching the area name if any do. If not, a list of stops or stations
  # matching the name if any do. 
  def self.place_from_name(name)
    errors = []
    # is it a postcode/partial postcode
    coord_info = self.coords_from_postcode(name)
    if ![:not_found, :bad_request, :not_postcode].include?(coord_info)
      zoom = MySociety::Validate.is_valid_postcode(name) ? MAX_VISIBLE_ZOOM : MAX_VISIBLE_ZOOM - 1
      return { :postcode_info => {:lat => coord_info['wgs84_lat'],
                                  :lon => coord_info['wgs84_lon'],
                                  :zoom => zoom }}
    elsif [:not_found, :bad_request].include?(coord_info)
      return { :postcode_info => {:error => coord_info }}
    end
    # is there an area with this name? 
    name = name.downcase
    localities = Locality.find_all_by_lower_name(name)
    if !localities.empty?
      return { :localities => localities }
    end
    # is there a stop/station with this name? 
    stops = Stop.find(:all, :conditions => ['(lower(common_name) like ? 
                                              OR lower(street) = ? 
                                              OR naptan_code = ?)
                                              AND stop_type in (?)',
                                            name, name, name, StopType.primary_types] )
    
    stations = StopArea.find(:all, :conditions => ["(lower(name) like ? 
                                                    OR lower(name) like ? 
                                                    OR lower(name) like ? 
                                                    OR code = ?)
                                                    AND area_type in (?)",
                                            name, "#{name} %", "% #{name}", name, StopAreaType.primary_types])
    if !stops.empty? or !stations.empty?
      return { :locations => stops + stations }
    end
    return {}
  end
  
  # accepts attributes
  # - name - stop/station name
  # - area - town/area
  # - transport_mode_id
  # - route_number - route number/name
  # options 
  # - limit - Number of results to return
  # - stops_only - Don't return stations
  def self.find_stops_and_stations_from_attributes(attributes, options={})
    transport_mode = TransportMode.find(attributes[:transport_mode_id])
    search_models = []
    if options[:stops_only]
      search_models << Stop
    else
      if ['Train', 'Tram/Metro', 'Ferry'].include? transport_mode.name
        search_models << StopArea
      end
      if ['Bus', 'Coach', 'Tram/Metro'].include? transport_mode.name
        search_models << Stop
      end
    end
    errors = []
    results = []
    self.postcode_from_area(attributes) if !attributes[:area].blank?
    includes = [:locality]
    order = nil
    search_models.each do |model_class|
      type_class = "#{model_class}Type".constantize
      query, params = type_class.conditions_for_transport_mode(attributes[:transport_mode_id])

      if !attributes[:postcode].blank?
        coord_info = coords_from_postcode(attributes[:postcode])
        if coord_info == :not_found or coord_info == :bad_request
          errors << :postcode_not_found
        else
          query += " AND ST_Distance(
                    ST_GeomFromText('POINT(? ?)', 
                    #{BRITISH_NATIONAL_GRID}), 
                    #{model_class.table_name}.coords) < 1000"
          params << coord_info['easting'].to_i
          params << coord_info['northing'].to_i
          order = "ST_Distance(
                    ST_GeomFromText('POINT(#{coord_info['easting'].to_i} #{coord_info['northing'].to_i})', 
                    #{BRITISH_NATIONAL_GRID}), 
                    #{model_class.table_name}.coords)"
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
        if model_class == Stop
          query += ' AND (lower(common_name) like ? OR lower(street) = ? OR naptan_code = ?)'
          params <<  "%#{name}%"
          params << name
          params << name
        else
          query += " AND (lower(name) like ? OR code = ?)"
          params <<  "%#{name}%"
          params << name
        end
      end
      if !attributes[:route_number].blank?
        route_results = find_routes_from_attributes(attributes)
        errors += route_results[:errors]
        if !route_results[:results].empty?
          query += ' AND route_segments.route_id in (?)'
          params << route_results[:results]
          if model_class == Stop
            includes << :route_segments_as_from_stop
            includes << :route_segments_as_to_stop
          else
            includes << :route_segments_as_from_stop_area
            includes << :route_segments_as_to_stop_area
          end
        end
      end
      conditions = [query] + params
      model_results = []
      if errors.empty? 
        model_results = model_class.find(:all, :conditions => conditions, 
                                         :limit => options[:limit], 
                                         :include => includes,
                                         :order => order)
      end
      # reduce redundant results for stop areas
      if model_results.size > 1 && model_class == StopArea
        model_results = StopArea.map_to_common_areas(model_results)
      end
      results += model_results
    end
    { :results => results, :errors => errors.uniq }
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
    
    select_clause = 'SELECT distinct routes.id'
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
      if coord_info == :not_found or coord_info == :bad_request
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
      where_clause += " AND (lower(routes.number) = ? OR lower(routes.name) like ?)"
      params << route_number
      params << "%#{route_number}%"
    end
    if limit 
      where_clause += " limit #{options[:limit]}"
    end
    params = ["#{select_clause} #{from_clause} #{where_clause}"] + params
    if errors.empty?
      routes = Route.find_by_sql(params)
      routes = Route.find(:all, :conditions => ['id in (?)', routes], 
                          :include => { :route_segments => [:from_stop => :locality, :to_stop => :locality], 
                                        :route_operators => :operator } )
    end
    { :results => routes, :errors => errors }
  end

end