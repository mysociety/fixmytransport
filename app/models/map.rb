# functions for allowing static maps to be generated
# currently works with google maps
class Map

  def self.offset
    268435456 # half of the earth's circumference in pixels at zoom level 21
  end

  def self.radius
    85445659.44705395 # offset / Math::PI
  end

  def self.radius_in_km
    6371
  end

  def self.zoom_in(zoom)
    (zoom < MAX_VISIBLE_ZOOM) ? zoom.to_i+1 : MAX_VISIBLE_ZOOM
  end

  def self.zoom_out(zoom)
    (zoom > MIN_ZOOM_LEVEL) ? zoom.to_i-1 : MIN_ZOOM_LEVEL
  end

  def self.top(lat, zoom, map_height)
    adjust_lat_by_pixels(lat, zoom, -map_height/2)
  end

  def self.bottom(lat, zoom, map_height)
    adjust_lat_by_pixels(lat, zoom, (map_height/2))
  end

  def self.adjust_lon_by_pixels(lon, zoom, delta)
    x_to_lon(lon_to_x(lon) + (delta << (MAX_ZOOM_LEVEL - zoom)))
  end

  def self.x_to_lon(x)
    ((x.round - offset) / radius) * 180 / Math::PI
  end

  def self.lon_to_x(lon)
    (offset +  lon * (radius * (Math::PI / 180.0))).round
  end

  def self.left(lon, zoom, map_width)
    adjust_lon_by_pixels(lon, zoom, -map_width/2)
  end

  def self.right(lon, zoom, map_width)
    adjust_lon_by_pixels(lon, zoom, map_width/2)
  end

  def self.adjust_lat_by_pixels(lat, zoom, delta)
    y_to_lat(lat_to_y(lat) + (delta << (MAX_ZOOM_LEVEL - zoom)))
  end

  def self.lat_to_y(lat)
    sin_val = Math::sin(lat * (Math::PI / 180))
    (offset - radius * Math::log((1 + sin_val) / (1 - sin_val)) / 2 ).round
  end

  def self.y_to_lat(y)
    (Math::PI / 2 - 2 * Math::atan(Math::exp((y.round - offset) / radius))) * 180 / Math::PI
  end

  def self.lat_to_y_offset(center_y, center_offset_y, lat, zoom)
    target_y = lat_to_y(lat)
    delta_y  = (target_y - center_y) >> (MAX_ZOOM_LEVEL - zoom)
    return center_offset_y + delta_y
  end

  def self.lon_to_x_offset(center_x, center_offset_x, lon, zoom)
    target_x = lon_to_x(lon)
    delta_x  = (target_x - center_x) >> (MAX_ZOOM_LEVEL - zoom)
    return center_offset_x + delta_x
  end

  def self.adjust_lon_by_pixels(lon, zoom, delta)
    x_to_lon(lon_to_x(lon) + (delta << (MAX_ZOOM_LEVEL - zoom)))
  end

  def self.zoom_to_coords(min_lon, max_lon, min_lat, max_lat, height, width)
    min_x = lon_to_x(min_lon)
    max_x = lon_to_x(max_lon)
    min_y = lat_to_y(min_lat)
    max_y = lat_to_y(max_lat)
    x_diff = (max_x - min_x).abs
    y_diff = (max_y - min_y).abs
    diff = [x_diff, y_diff].max
    return MAX_VISIBLE_ZOOM - 1 if diff == 0
    diff_over_dimension = [(x_diff/width), (y_diff/height)].max
    return MAX_VISIBLE_ZOOM if diff_over_dimension == 0
    zoom = MAX_ZOOM_LEVEL - (Math::log(diff_over_dimension) / Math::log(2)).ceil
    if zoom > MAX_VISIBLE_ZOOM
      zoom = MAX_VISIBLE_ZOOM
    end
    zoom
  end

  # calculate the Haversine distance between two coords expressed as lats and lons
  # http://www.movable-type.co.uk/scripts/latlong.html
  # to one decimal place
  def self.distance_in_km(from, to)

    delta_lon = to[:lon] - from[:lon]
    delta_lat = to[:lat] - from[:lat]

    deg_to_rad = (Math::PI / 180.0)

    delta_lon_rad = delta_lon * deg_to_rad
    delta_lat_rad = delta_lat * deg_to_rad

    from_lat_rad = from[:lat] * deg_to_rad
    to_lat_rad = to[:lat] * deg_to_rad

    a = (Math.sin(delta_lat_rad/2))**2 + Math.cos(from_lat_rad) * Math.cos(to_lat_rad) * (Math.sin(delta_lon_rad/2))**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))

    (self.radius_in_km * c).round(1) # delta in kilometers
  end

  def self.google_tile_url(lat, lon, zoom, map_height, map_width)
    "http://maps.google.com/maps/api/staticmap?center=#{lat},#{lon}&zoom=#{zoom}&size=#{map_width}x#{map_height}&sensor=false"
  end

  def self.issue_data(map_corners, options)
    issue_data = Problem.find_issues_in_bounding_box(map_corners)
    if issue_data[:issues].size < 10
      lat = options[:lat]
      lon = options[:lon]
      zoom = options[:zoom]
      # Calculate the distance from the centre of a map twice the size of the current map to its
      # bottom right corner
      bottom = self.bottom(lat, zoom, options[:map_height]*2)
      right = self.right(lon, zoom, options[:map_width]*2)
      issue_data[:distance] = self.distance_in_km({:lat => lat, :lon => lon}, {:lat => bottom, :lon => right})
      nearest_options = { :exclude_ids => issue_data[:problem_ids] }
      issue_data[:nearest_issues] = Problem.find_nearest_issues(lat, lon, issue_data[:distance], nearest_options)
    end
    return issue_data
  end

  def self.other_locations(lat, lon, zoom, map_height, map_width, highlight=nil)
    options = { :highlight => highlight,
                :lat => lat,
                :lon => lon,
                :zoom => zoom,
                :map_height => map_height,
                :map_width => map_width }
    data = { :locations => [], :stop_ids => [], :stop_area_ids => [] }
    # If the zoom is further out than MIN_ZOOM_FOR_HIGHLIGHTED_MARKERS
    # then no data is returned.
    if zoom >= MIN_ZOOM_FOR_OTHER_MARKERS
      # i.e. if we're very zoomed-in, include other markers:
      map_corners = self.calculate_map_corners(lat, lon, zoom, map_height, map_width)
      if highlight == :has_content
        data = self.issue_data(map_corners, options)
      end
      stop_data = Stop.find_in_bounding_box(map_corners, {:exclude_ids => data[:stop_ids]})
      stop_area_data = StopArea.find_in_bounding_box(map_corners, {:exclude_ids => data[:stop_area_ids]})
      # want issue data markers (if any) drawn last so they'll be on top
      data[:locations] = stop_data + stop_area_data + data[:locations]
    elsif highlight && zoom >= MIN_ZOOM_FOR_HIGHLIGHTED_MARKERS
      # i.e. highlight is on, and we're not zoomed out too far
      map_corners = self.calculate_map_corners(lat, lon, zoom, map_height, map_width)
      data = self.issue_data(map_corners, options)
    end
    data
  end

  def self.calculate_map_corners(lat, lon, zoom, map_height, map_width)
    bottom = bottom(lat, zoom, map_height)
    top = top(lat, zoom, map_height)
    left = left(lon, zoom, map_width)
    right = right(lon, zoom, map_width)
    return { :bottom => bottom, :top => top, :left => left, :right => right }
  end

end