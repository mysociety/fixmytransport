# functions for allowing static maps to be generated
# currently works with google maps
class Map
  
  def self.offset
    268435456 # half of the earth's circumference in pixels at zoom level 21
  end
  
  def self.radius
    85445659.44705395 # offset / Math::PI
  end
  
  def self.zoom_in(zoom)
    (zoom < MAX_VISIBLE_ZOOM) ? zoom.to_i+1 : MAX_VISIBLE_ZOOM
  end
  
  def self.zoom_out(zoom)
    (zoom > MIN_ZOOM_LEVEL) ? zoom.to_i-1 : MIN_ZOOM_LEVEL
  end
  
  def self.top(lon, zoom)
    adjust_lon_by_pixels(lon, zoom, MAP_HEIGHT_IN_PX/2)
  end

  def self.bottom(lon, zoom)
    adjust_lon_by_pixels(lon, zoom, -MAP_HEIGHT_IN_PX/2)
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
  
  def self.left(lat, zoom)
    adjust_lat_by_pixels(lat, zoom, MAP_WIDTH_IN_PX/2)
  end
  
  def self.right(lat, zoom)
    adjust_lat_by_pixels(lat, zoom, -MAP_WIDTH_IN_PX/2)
  end
  
  def self.adjust_lat_by_pixels(lat, zoom, delta)
    y_to_lat(lat_to_y(lat) + (delta << (MAX_ZOOM_LEVEL - zoom)))
  end
  
  def self.lat_to_y(lat)
    (offset - radius * Math::log((1 + Math::sin(lat * (Math::PI / 180))) / (1 - Math::sin(lat * (Math::PI / 180)))) / 2 ).round
  end
  
  def self.y_to_lat(y)
    (Math::PI / 2 - 2 * Math::atan(Math::exp((y.round - offset) / radius))) * 180 / Math::PI
  end
  
  def self.lat_to_y_offset(center_lat, lat, zoom)
    center_y = lat_to_y(center_lat)
    target_y = lat_to_y(lat)
    delta_y  = (target_y - center_y) >> (MAX_ZOOM_LEVEL - zoom)
    center_offset_y = MAP_HEIGHT_IN_PX / 2 
    return center_offset_y + delta_y
  end
  
  def self.lon_to_x_offset(center_lon, lon, zoom)
    center_x = lon_to_x(center_lon)
    target_x = lon_to_x(lon)
    delta_x  = (target_x - center_x) >> (MAX_ZOOM_LEVEL - zoom)
    center_offset_x = MAP_WIDTH_IN_PX / 2
    return center_offset_x + delta_x
  end
  
  def self.adjust_lon_by_pixels(lon, zoom, delta)
    x_to_lon(lon_to_x(lon) + (delta << (MAX_ZOOM_LEVEL - zoom)))
  end
  
  def self.x_to_lon(x)
    ((x.round - offset) / radius) * 180 / Math::PI 
  end
    
  def self.zoom_to_coords(min_lon, max_lon, min_lat, max_lat)
    min_x = lon_to_x(min_lon)
    max_x = lon_to_x(max_lon)
    min_y = lat_to_y(min_lat)
    max_y = lat_to_y(max_lat)
    x_diff = (max_x - min_x).abs
    y_diff = (max_y - min_y).abs
    diff = [x_diff, y_diff].max
    return MAX_VISIBLE_ZOOM - 1 if diff == 0
    diff_over_width = diff / MAP_WIDTH_IN_PX
    zoom = MAX_ZOOM_LEVEL - (Math::log(diff_over_width) / Math::log(2)).ceil 
    if zoom > MAX_VISIBLE_ZOOM
      zoom = MAX_VISIBLE_ZOOM
    end
    zoom
  end
  
  def self.google_tile_url(lat, lon, zoom)
    "http://maps.google.com/maps/api/staticmap?center=#{lat},#{lon}&zoom=#{zoom}&size=#{MAP_WIDTH_IN_PX}x#{MAP_WIDTH_IN_PX}&sensor=false"
  end

  def self.other_locations(lat, lon, zoom)
    if zoom >= MIN_ZOOM_FOR_OTHER_MARKERS
      bottom = bottom(lat, zoom)
      top = top(lat, zoom)
      left = left(lon, zoom)
      right = right(lon, zoom)
      locations = Stop.find_in_bounding_box(bottom, left, top, right)
      locations += StopArea.find_in_bounding_box(bottom, left, top, right)
    else
      locations = []
    end
    locations
  end

end