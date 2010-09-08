# functions for allowing static maps to be generated
# currently works with google maps
class Map
  
  def self.deg2rad(deg)
  	(deg * Math::PI / 180)
  end

  def self.rad2deg(rad)
  	(rad * 180 / Math::PI)
  end
  
  # lon/lat to tile numbers
  def self.lon_lat_to_tile_num(lat_deg, lon_deg, zoom)
   lat_rad = deg2rad(lat_deg)
   n = 2.0 ** zoom
   xtile = ((lon_deg + 180.0) / 360.0 * n).to_i
   ytile = ((1.0 - Math.log(Math.tan(lat_rad) + (1 / Math.cos(lat_rad))) / Math::PI) / 2.0 * n).to_i
   return xtile, ytile
  end
  
  # tile numbers to lon/lat
  def self.num2deg(xtile, ytile, zoom)
   n = 2.0 ** zoom
   lon_deg = xtile / n * 360.0 - 180.0
   lat_rad = math.atan(Math.sinh(math.pi * (1 - 2 * ytile / n)))
   lat_deg = rad2deg(lat_rad)
   return lat_deg, lon_deg
  # This returns the NW-corner of the square. Use the function with xtile+1 and/or ytile+1 to get the other corners. With xtile+0.5 & ytile+0.5 it will return the center of the tile
  end
  
  def self.tile_url(lat, lon, zoom)
    x, y = deg2num(lat, lon, zoom)
    return "http://tile.openstreetmap.org/#{zoom}/#{x}/#{y}.png"
  end
  
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
    end
  
  def self.google_tile_url(lat, lon, zoom)
    "http://maps.google.com/maps/api/staticmap?center=#{lat},#{lon}&zoom=#{zoom}&size=#{MAP_WIDTH_IN_PX}x#{MAP_WIDTH_IN_PX}&sensor=false"
  end

end