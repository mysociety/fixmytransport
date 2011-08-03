module FixMyTransport
  
  module GeoFunctions
        
  # set the coordinate attributes in a given system of a model instance that has coords.
    def set_coords(instance, class_name, coords_system, x_attr, y_attr)
      conn = ActiveRecord::Base.connection
      result = conn.execute("SELECT st_X(st_transform(coords,#{coords_system})) as x,
                                    st_Y(st_transform(coords,#{coords_system})) as y
                             FROM #{class_name.tableize}
                             WHERE id = #{instance.id}")

      x, y = coords_from_result(result)
      instance.send("#{x_attr}=".to_sym, x)
      instance.send("#{y_attr}=".to_sym, y)
      return instance
    end

    def coords_from_result(result)
      x_y = result[0]
      if x_y.is_a? Hash
        x = x_y["x"]
        y = x_y["y"]
      else
        x, y = x_y
      end
      [x, y]
    end

    def set_lon_lat(instance, class_name)
      set_coords(instance, class_name, WGS_84, :lon, :lat)
    end

    def set_easting_northing(instance, class_name)
      set_coords(instance, class_name, BRITISH_NATIONAL_GRID, :easting, :northing)
    end

    def get_easting_northing(lon, lat)
      conn = ActiveRecord::Base.connection
      result = conn.execute("SELECT st_X(
                                      st_transform(
                                        ST_GeomFromText('POINT(#{lon} #{lat})', #{WGS_84}), 
                                        #{BRITISH_NATIONAL_GRID})) as x, 
                                    st_Y(
                                      st_transform(
                                        ST_GeomFromText('POINT(#{lon} #{lat})', #{WGS_84}), 
                                        #{BRITISH_NATIONAL_GRID})) as y
                             FROM stops 
                             LIMIT 1")
      easting, northing = coords_from_result(result)
    end

  end
end