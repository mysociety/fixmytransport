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
  def self.place_from_name(name, stop_name=nil)
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
    name = name.downcase.strip
    localities = Locality.find_all_by_full_name(name)

    # we've been passed a unique place name and a stop name
    if localities.size == 1 and !stop_name.nil?
      stop_name = stop_name.downcase.strip
      stops = Stop.find(:all, :conditions => ['(lower(common_name) = ?
                                                OR lower(common_name) like ?
                                                OR lower(street) = ?
                                                OR naptan_code = ?)
                                                AND stop_type in (?)
                                                AND locality_id = ?',
                                              stop_name, "#{stop_name} %", stop_name, stop_name,
                                              StopType.primary_types, localities.first] )
      stations = self.find_stations_from_name(stop_name, exact=false, {:types => StopAreaType.primary_types,
                                                                       :locality => localities.first})

      return { :locations => stops + stations }
    end

    if !localities.empty?
      return { :localities => localities }
    end

    # is there a stop/station with this name?
    stops = Stop.find(:all, :conditions => ['(lower(common_name) = ?
                                              OR lower(common_name) like ?
                                              OR lower(street) = ?
                                              OR naptan_code = ?)
                                              AND stop_type in (?)',
                                            name, "#{name} %", name, name, StopType.primary_types] )

    stations = self.find_stations_from_name(name, exact=false, {:types => StopAreaType.primary_types})
    candidates = stops + stations
    # are the stops/stations in multiple areas? Simplify things by showing the areas
    if stops.size > 1 or stations.size > 1
      localities = candidates.map{ |stop_or_station| stop_or_station.locality }.uniq.sort_by(&:name)
      if localities.size > 1 and localities.size < candidates.size
        return { :localities => localities, :matched_stops_or_stations => true}
      end
    end

    if !stops.empty? or !stations.empty?
      return { :locations => stops + stations }
    end
    # try a sounds-like area search
    localities = Locality.find_by_double_metaphone(name)
    if !localities.empty?
      return { :localities => localities }
    end
    return {}
  end

  def self.bus_route_from_route_number(route_number, area, limit, ignore_area=false, area_type=nil)
    error = nil
    select_clause = 'SELECT distinct routes.id, routes.cached_description'
    from_clause = 'FROM routes'
    params = []
    route_number = route_number.downcase.strip
    where_clause = "WHERE (lower(routes.number) = ? OR lower(routes.name) like ?) "
    params << route_number
    params << "%#{route_number}%"
    where_clause += " AND transport_mode_id in (?)"
    params << [TransportMode.find_by_name('Bus'), TransportMode.find_by_name('Coach')]
    areas = []
    if ignore_area
      error = :route_not_found_in_area
    else
      area = area.strip
      # area is postcode
      coord_info = self.coords_from_postcode(area)
      if coord_info == :not_found or coord_info == :bad_request
        error = :postcode_not_found
      elsif coord_info == :not_postcode
        areas = Locality.find_areas_by_name(area, area_type)
        if areas.size > 1
          return { :areas => areas }
        end
      else
        if MySociety::Validate.is_valid_partial_postcode(area)
          distance = 5000
        else
          distance = 1000
        end
        areas = Locality.find_by_coordinates(coord_info['easting'], coord_info['northing'], distance)
      end
      if areas.empty? and !error
        error = :area_not_found
      end
      if !areas.empty?
        localities = Locality.find_with_descendants(areas.first)
        from_clause += ", route_localities"
        where_clause += " AND route_localities.route_id = routes.id
                          AND route_localities.locality_id in (?)"
        params << localities
      end
    end
    where_clause += " order by cached_description"
    if limit
      where_clause += " limit #{limit}"
    end
    params = ["#{select_clause} #{from_clause} #{where_clause}"] + params
    routes = Route.find_by_sql(params)
    routes = Route.find(:all, :conditions => ['id in (?)', routes], :order => 'cached_description' )
    if routes.empty? and !ignore_area and !areas.empty?
      return bus_route_from_route_number(route_number, area, limit, ignore_area=true)
    end
    return { :routes => routes, :error => error }
  end

  def self.other_route_from_stations(from, from_exact, to, to_exact)
    errors = Hash.new{ |hash, key| hash[key] = [] }
    station_types = ['GTMU', 'GFTD']

    from_stops = Gazetteer.find_stations_from_name(from.strip, from_exact, :types => station_types)
    to_stops = Gazetteer.find_stations_from_name(to.strip, to_exact, :types => station_types)

    # if there are multiple stations with the exact same name, don't ask the user to select one
    # just pass them all to find_all_by_locations, and see which one has the route
    
    if from_stops.size > 1 && from_stops.map{ |stop| stop.name }.uniq.size > 1
      errors[:from_stop] << I18n.translate('problems.find_other_route.ambiguous_from_stop', :station_name => from.strip)
    end
    if to_stops.size > 1 && to_stops.map{ |stop| stop.name }.uniq.size > 1
      errors[:to_stop] << I18n.translate('problems.find_other_route.ambiguous_to_stop', :station_name => to.strip)
    end
    if from_stops.size == 0
      errors[:from_stop] << I18n.translate('problems.find_other_route.from_stop_not_found')
    end
    if to_stops.size == 0
      errors[:to_stop] << I18n.translate('problems.find_other_route.to_stop_not_found')
    end
    if ! errors.empty?
      return { :errors => errors,
               :from_stops => from_stops,
               :to_stops => to_stops }
    end
    find_options = { :transport_modes => [TransportMode.find_by_name('Ferry').id,
                                          TransportMode.find_by_name('Tram/Metro').id],
                     :as_terminus => false }
    routes = Route.find_all_by_locations([from_stops, to_stops], find_options)
    return { :routes => routes, :from_stops => from_stops, :to_stops => to_stops }
  end

  def self.train_route_from_stations(from, from_exact, to, to_exact)
    errors = Hash.new{ |hash, key| hash[key] = [] }

    from_stops = Gazetteer.find_stations_from_name(from.strip, from_exact, :types => ['GRLS'])
    to_stops = Gazetteer.find_stations_from_name(to.strip, to_exact, :types => ['GRLS'])

    # if there are multiple stations with the exact same name, don't ask the user to select one
    # just pass them all to find_all_by_locations, and see which one has the route
    if from_stops.size > 1 && from_stops.map{ |stop| stop.name }.uniq.size > 1
      errors[:from_stop] << I18n.translate('problems.find_train_route.ambiguous_from_stop', :station_name => from.strip)
    end
    if to_stops.size > 1 && to_stops.map{ |stop| stop.name }.uniq.size > 1
      errors[:to_stop] << I18n.translate('problems.find_train_route.ambiguous_to_stop', :station_name => to.strip)
    end
    if from_stops.size == 0
      errors[:from_stop] << I18n.translate('problems.find_train_route.from_stop_not_found')
    end
    if to_stops.size == 0
      errors[:to_stop] << I18n.translate('problems.find_train_route.to_stop_not_found')
    end
    if ! errors.empty?
      return { :errors => errors,
               :from_stops => from_stops,
               :to_stops => to_stops }
    end
    find_options = { :transport_modes => [TransportMode.find_by_name('Train').id],
                     :as_terminus => false }
    routes = Route.find_all_by_locations([from_stops, to_stops], find_options)
    return { :routes => routes, :from_stops => from_stops, :to_stops => to_stops }
  end

  def self.normalize_station_name(name)
    name.gsub(/(( train| railway| rail| tube)? station)$/i, '')
  end

  def self.find_stations_by_double_metaphone(name, options={})
    query = 'area_type in (?)'
    params = [options[:types]]
    primary_metaphone, secondary_metaphone = Text::Metaphone.double_metaphone(name)
    query += ' AND primary_metaphone = ?'
    params << primary_metaphone
    if options[:locality]
      query += ' AND locality_id = ?'
      params << options[:locality]
    end
    conditions = [query] + params
    results = StopArea.find(:all, :conditions => conditions,
                                  :limit => options[:limit], :order => 'name')
  end

  # - name - stop/station name
  # options
  # - limit - Number of results to return
  # - types - The area_types to constrain the search
  def self.find_stations_from_name(name, exact, options={})
    results = self._find_stations_from_name(name, exact, options)
    
    # try variations on and
    if results.empty? and !exact
      name_with_ampersand = name.gsub(' and ', ' & ')
      if name_with_ampersand != name
        results = self._find_stations_from_name(name_with_ampersand, exact, options)
      else
        name_with_and = name.gsub(' & ', ' and ')
        if name_with_and != name
          results = self._find_stations_from_name(name_with_and, exact, options)
        end
      end  
    end
      
    if results.empty? and !exact
      results = self.find_stations_by_double_metaphone(name, options)
    end

    # reduce redundant results for stop areas
    if results.size > 1
      results = StopArea.map_to_common_areas(results)
    end
    results
  end
  
  def self._find_stations_from_name(name, exact, options)
    query = 'area_type in (?)'
    params = [options[:types]]
    name = name.downcase.strip
    if exact
      query += " AND lower(name) = ?"
      params << name
    else
      name = self.normalize_station_name(name)
      query += " AND (lower(name) like ?
                 OR lower(name) like ?
                 OR lower(name) like ?
                 OR lower(name) like ?
                 OR code = ?)"
      params <<  "#{name}"
      params <<  "#{name} %"
      params <<  "% #{name} %"
      params <<  "% #{name}"
      params << name
    end

    if options[:locality]
      query += " AND locality_id = ?"
      params << options[:locality]
    end

    conditions = [query] + params
    results = StopArea.find(:all, :conditions => conditions,
                                  :limit => options[:limit], :order => 'name')
  end
end