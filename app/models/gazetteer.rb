require 'mechanize'

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
    stops = Stop.find(:all, :conditions => ['(lower(common_name) = ? 
                                              OR lower(common_name) like ? 
                                              OR lower(street) = ? 
                                              OR naptan_code = ?)
                                              AND stop_type in (?)',
                                            name, "#{name} %", name, name, StopType.primary_types] )
    
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
  
  def self.bus_route_from_route_number(route_number, area, limit, ignore_area=false)
    error = nil
    select_clause = 'SELECT distinct routes.id'
    from_clause = 'FROM routes'
    params = []
    route_number = route_number.downcase
    where_clause = "WHERE (lower(routes.number) = ? OR lower(routes.name) like ?) "
    params << route_number
    params << "%#{route_number}%"
    localities = []  
    if ignore_area
      error = :route_not_found_in_area
    else
      # area is postcode
      coord_info = self.coords_from_postcode(area)
      if coord_info == :not_found or coord_info == :bad_request
        error = :postcode_not_found
      elsif coord_info == :not_postcode
        localities = Locality.find_all_with_descendants(area)
      else
        if MySociety::Validate.is_valid_partial_postcode(area)
          distance = 5000
        else
          distance = 1000
        end
        localities = Locality.find_by_coordinates(coord_info['easting'], coord_info['northing'], distance)
      end
      if localities.empty? and !error
        error = :area_not_found
      else
        from_clause += ", route_localities"
        where_clause += " AND route_localities.route_id = routes.id
                          AND route_localities.locality_id in (?)"
        params << localities
      end    
    end
    if limit 
      where_clause += " limit #{limit}"
    end
    params = ["#{select_clause} #{from_clause} #{where_clause}"] + params
    routes = Route.find_by_sql(params)
    routes = Route.find(:all, :conditions => ['id in (?)', routes] )
    if routes.empty? and !ignore_area and !localities.empty?
      return bus_route_from_route_number(route_number, area, limit, ignore_area=true)
    end
    return { :routes => routes, :error => error }
  end
  
  def self.other_route_from_stations(from, to)
    errors = []  
    station_types = ['GTMU', 'GFTD']
    
    from_stops = Gazetteer.find_stations_from_name(from.strip, :types => station_types)
    to_stops = Gazetteer.find_stations_from_name(to.strip, :types => station_types)

    if from_stops.size > 1
      errors << :ambiguous_from_stop
    end
    if to_stops.size > 1
      errors << :ambiguous_to_stop
    end
    if from_stops.size == 0
      errors << :from_stop_not_found
    end
    if to_stops.size == 0
      errors << :to_stop_not_found
    end
    if ! errors.empty? 
      return { :errors => errors, 
               :from_stops => from_stops,
               :to_stops => to_stops }
    end
    routes = Route.find_all_by_locations([from_stops, to_stops], 
                                         [TransportMode.find_by_name('Ferry').id, TransportMode.find_by_name('Tram/Metro').id], 
                                         as_terminus=false, 
                                         limit=nil)
    return { :routes => routes, :from_stops => from_stops, :to_stops => to_stops }
  end
  
  def self.train_route_from_stations_and_time(from, to, time=nil)  
    errors = []  
    
    from_stops = Gazetteer.find_stations_from_name(from.strip, :types => ['GRLS'])
    to_stops = Gazetteer.find_stations_from_name(to.strip, :types => ['GRLS'])
    
    if from_stops.size > 1
      errors << :ambiguous_from_stop
    end
    if to_stops.size > 1
      errors << :ambiguous_to_stop
    end
    if from_stops.size == 0
      errors << :from_stop_not_found
    end
    if to_stops.size == 0
      errors << :to_stop_not_found
    end
    if ! errors.empty? 
      return { :errors => errors, 
               :from_stops => from_stops,
               :to_stops => to_stops }
    end
    routes = Route.find_all_by_locations([from_stops, to_stops], 
                                         TransportMode.find_by_name('Train').id, 
                                         as_terminus=false, 
                                         limit=nil)
    return { :routes => routes, :from_stops => from_stops, :to_stops => to_stops } 
  end
  
  # - name - stop/station name
  # options 
  # - limit - Number of results to return
  def self.find_stations_from_name(name, options={})
    query = 'area_type in (?)'
    params = [options[:types]]   
    name = name.downcase 
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
    conditions = [query] + params
    results = StopArea.find(:all, :conditions => conditions, 
                                  :limit => options[:limit])  
    # reduce redundant results for stop areas
    if results.size > 1 
      results = StopArea.map_to_common_areas(results)
    end     
    results                 
  end
  

end