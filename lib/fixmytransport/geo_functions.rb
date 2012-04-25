module FixMyTransport

  # Functions for handling coordinate conversion
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

    # convert national grid coords into lat/lons. Is not recorded as a replayable change
    def convert_coords(class_name, task_name, conditions = nil)
      model_class = class_name.constantize
      if model_class.respond_to?(:replayable)
        previous_replayable_value = model_class.replayable
        model_class.replayable = false
      end
      model_class.find_each(:conditions => conditions) do |instance|
        instance = set_lon_lat(instance, class_name)
        instance.save!
      end
      if model_class.respond_to?(:replayable)
        model_class.replayable = previous_replayable_value
      end
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

    def get_lon_lat(easting, northing)
      conn = ActiveRecord::Base.connection
      result = conn.execute("SELECT st_X(
                                      st_transform(
                                        ST_GeomFromText('POINT(#{easting} #{northing})', #{BRITISH_NATIONAL_GRID}),
                                        #{WGS_84})) as x,
                                    st_Y(
                                      st_transform(
                                        ST_GeomFromText('POINT(#{easting} #{northing})', #{BRITISH_NATIONAL_GRID}),
                                        #{WGS_84})) as y
                             FROM stops
                             LIMIT 1")
      lon, lat = coords_from_result(result)
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
      [easting.to_f.round, northing.to_f.round]
    end

  end
end