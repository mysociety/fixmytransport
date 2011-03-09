begin
  require 'xml'
rescue LoadError
  require 'xml/libxml'
end
require 'zip/zip'
require 'test/unit'

class Parsers::TransxchangeParser

  include Test::Unit::Assertions
  attr_accessor :admin_area, :filename

  def initialize
  end

  # Go through a directory and look for zip files in each directory. Get a stream from every
  # zip file found and pass it to parse_routes
  def parse_all_routes(dirname, transport_mode=nil)
    Dir.glob(File.join(dirname, '*/')).each do |subdir|
      zips = Dir.glob(File.join(subdir, '*.zip'))
      zips.each do |zip|
        Zip::ZipFile.foreach(zip) do |txc_file|
          puts txc_file
          @filename = txc_file.to_s
          data_from_filename
          if transport_mode
            next unless @mode.name == transport_mode
          end
          parse_routes(txc_file.get_input_stream())
        end
      end
    end
  end

  def data_from_filename
    name_parts = File.basename(@filename, '.txc').split("_")
    admin_area_code = name_parts[1]
    @admin_area = AdminArea.find_by_atco_code(admin_area_code)
    @region = @admin_area.region
    vehicle_type = name_parts[2]
    mode_from_filename(vehicle_type)
  end

  def mode_from_filename(vehicle_type)
    mode_name = case vehicle_type
    when 'BUS'
      'Bus'
    when 'COACH'
      'Coach'
    when 'TRAIN'
      'Train'
    when 'FERRY'
      'Ferry'
    when 'METRO'
      'Tram/Metro'
    else
      raise "Unknown vehicle type #{vehicle_type} from file #{@filename}"
    end
    @mode = TransportMode.find_by_name(mode_name)
  end

  def mark_stop_code_missing(missing_stops, stop_code, route)
    if ! missing_stops[stop_code]
      missing_stops[stop_code] = []
    end
    route_string = "#{route.type} #{route.number}"
    if ! missing_stops[stop_code].include?(route_string)
      missing_stops[stop_code] << route_string
    end
    return missing_stops
  end

  def add_route_journey_pattern(route)
  end
  def parse_routes(input)
    @routes = []
    missing_stops = {}
    if input.is_a?(String)
      @filename = input
      @reader = XML::Reader.file(input)
    else
      @reader = XML::Reader.io(input)
    end
    data_from_filename()
    while @reader.read
      case @reader.node_type
        when XML::Reader::TYPE_ELEMENT
          handle_element
        when XML::Reader::TYPE_SIGNIFICANT_WHITESPACE
        when XML::Reader::TYPE_END_ELEMENT
          handle_end_element
        else
          raise "Unhandled type: #{@reader.node_type} #{@reader.name}"
      end
    end
    stop_options = {:includes => {:stop_area_memberships => :stop_area}}
    @routes.each do |route|

      puts route.number
      route.region = @region
      missing = []
      # route.route_source_admin_areas.build({:source_admin_area => @admin_area,
                                            # :operator_code => route.operator_code})


      route_regions = []
      route.journey_pattern_data.each do |journey_pattern_id, journey_pattern|
        i = 0
        journey_pattern[:section_refs].each do |section_ref|
          section = @journey_pattern_sections[section_ref]
          jp = route.journey_patterns.build(:destination => journey_pattern[:destination_display])
          section[:timing_links].each do |timing_link|
            from_stop = Stop.find_by_code(timing_link[:from_info][:stop], stop_options)
            to_stop = Stop.find_by_code(timing_link[:to_info][:stop], stop_options)

            if !from_stop
              missing << timing_link[:from_info][:stop]
            end
            if !to_stop
              missing << timing_link[:to_info][:stop]
            end

            route_segment = jp.route_segments.build(:from_stop => from_stop,
                                                    :to_stop   => to_stop,
                                                    :route => route,
                                                    :segment_order => i )
            if i == 0
              route_segment.from_terminus = true
            end
            if i == (section[:timing_links].size - 1)
              route_segment.to_terminus = true
            end
            # route_segment.set_stop_areas
            i += 1
          end
        end
      end
      missing.each do |missing_stop_code|
        missing_stops = self.mark_stop_code_missing(missing_stops, missing_stop_code, route)
      end
      operators = Operator.find_all_by_nptdr_code(@mode, route.operator_code, @region, route)
      operators.each do |operator|
        route.route_operators.build({ :operator => operator })
      end
      yield route
    end
    return missing_stops
  end

  def handle_end_element
    if ! @reader.name == 'TransXChange'
      raise "Unexpected end element #{@reader.name}"
    end
  end

  def handle_element
    ignored = [ 'TransXChange' ]
    handlers = { 'ServicedOrganisations'  => :handle_serviced_organisations,
                 'StopPoints'             => :handle_stop_points,
                 'JourneyPatternSections' => :handle_journey_pattern_sections,
                 'Operators'              => :handle_operators,
                 'Services'               => :handle_services,
                 'VehicleJourneys'        => :handle_vehicle_journeys }

    if handlers.include?(@reader.name)
      self.send(handlers[@reader.name])
    elsif ignored.include?(@reader.name)
    else
      raise "Unhandled element #{@reader.name}"
    end
  end

  def handle_serviced_organisations
    until_element_end(@reader.name)
  end

  def handle_stop_points
    until_element_end(@reader.name)
  end

  def handle_journey_pattern_sections
    @journey_pattern_sections = {}
    handle_multiple(@reader.name, 'JourneyPatternSection', :handle_journey_pattern_section)
  end

  def handle_journey_pattern_section
    @journey_pattern_section = {}
    @journey_pattern_section[:id] = get_attribute(@reader.name, 'id')
    @journey_pattern_section[:timing_links] = []
    handle_multiple(@reader.name, 'JourneyPatternTimingLink', :handle_timing_link)
    @journey_pattern_sections[@journey_pattern_section[:id]] = @journey_pattern_section
  end

  def handle_timing_link
    timing_link = {}
    until_element_end(@reader.name) do
      case @reader.name
      when 'From'
        timing_link[:from_info] = handle_link_terminus
      when 'To'
        timing_link[:to_info] = handle_link_terminus
      when 'RunTime'
        get_element_text('RunTime')
      else
        raise "Unexpected element in JourneyPatternTimingLink: #{@reader.name}"
      end
    end
    @journey_pattern_section[:timing_links] << timing_link
  end

  def handle_link_terminus
    terminus_info = {}
    until_element_end(@reader.name) do
      case @reader.name
      when 'StopPointRef'
        terminus_info[:stop] = get_element_text('StopPointRef').strip
      when 'WaitTime'
        get_element_text('WaitTime')
      when 'TimingStatus'
        get_element_text('TimingStatus')
      when 'Activity'
        get_element_text('Activity')
      else
        raise "Unexpected element in From: #{@reader.name}"
      end
    end
    return terminus_info
  end

  def handle_operators
    until_element_end(@reader.name)
  end

  def handle_services
    handle_multiple(@reader.name, 'Service', :handle_service)
  end

  def handle_service
    route_type = @mode.route_type.constantize
    @route = route_type.new(:transport_mode => @mode)
    until_element_end(@reader.name) do
      case @reader.name
      when 'ServiceCode'
        @route.number = get_element_text('ServiceCode')
      when 'Lines'
        handle_lines
      when 'OperatingPeriod'
        handle_operating_period
      when 'RegisteredOperatorRef'
        @route.operator_code = get_element_text('RegisteredOperatorRef')
      when 'StopRequirements'
        handle_stop_requirements
      when 'StandardService'
        handle_standard_service
      else
        raise "Unexpected element in services #{@reader.name}"
      end
    end
    @routes << @route
  end

  def handle_stop_requirements
    until_element_end(@reader.name)
  end

  def handle_standard_service
    @journey_patterns = {}
    until_element_end(@reader.name) do
      case @reader.name
      when 'Origin'
        get_element_text('Origin')
      when 'Destination'
        get_element_text('Destination')
      when 'JourneyPattern'
        handle_journey_pattern
      else
        raise "Unexpected element in StandardService: #{@reader.name}"
      end
    end
    @route.journey_pattern_data = @journey_patterns
  end

  def handle_journey_pattern
    journey_pattern = {}
    journey_pattern[:id] = get_attribute(@reader.name, 'id')
    journey_pattern[:section_refs] = []
    until_element_end(@reader.name) do
      case @reader.name
      when 'DestinationDisplay'
        journey_pattern[:destination_display] = get_element_text('DestinationDisplay')
      when 'Direction'
        journey_pattern[:direction] = get_element_text('Direction')
      when 'JourneyPatternSectionRefs'
        journey_pattern[:section_refs] << get_element_text('JourneyPatternSectionRefs')
      else
        raise "Unexpected element in JourneyPattern: #{@reader.name}"
      end
    end
    @journey_patterns[journey_pattern[:id]] = journey_pattern
  end

  def handle_operating_period
    until_element_end(@reader.name)
  end

  def handle_lines
    @lines = []
    handle_multiple(@reader.name, 'Line', :handle_line)
  end

  def handle_line
    line_info = {}
    line_info[:id] = get_attribute(@reader.name, 'id')
    until_element_end(@reader.name) do
      line_info[:name] = get_element_text('LineName')
    end
    @lines << line_info
    raise "More than one line for route #{@route.inspect} #{@lines.inspect}" if @lines.size > 1
  end

  def handle_vehicle_journeys
    until_element_end(@reader.name)
  end

  def handle_multiple(element_name, inner_element, handler)
    until_element_end(element_name) do
      if @reader.name == inner_element
        self.send(handler)
      else
        raise "Unexpected element in #{element_name}: #{@reader.name}"
      end
    end
  end

  # just extract the contents of a simple element - expects one text node
  def get_element_text(element_name)
    text = nil
    until_element_end(element_name) do
      raise "More than one text element in get_element_text: #{text} and #{@reader.value}" if !text.nil?
      assert_equal(XML::Reader::TYPE_TEXT, @reader.node_type)
      text = @reader.value
    end
    return text
  end

  def get_attribute(element_name, attribute)
    if ! @reader.has_attributes?
      raise "No attributes in #{element_name}"
    end
    return @reader[attribute]
  end

  # yield all the elements and text until this element closes, ignore element ends and whitespace
  def until_element_end(name)
    while !(@reader.node_type == XML::Reader::TYPE_END_ELEMENT && @reader.name == name)
      @reader.read
      case @reader.node_type
        when XML::Reader::TYPE_SIGNIFICANT_WHITESPACE
        when XML::Reader::TYPE_END_ELEMENT
        when XML::Reader::TYPE_ELEMENT, XML::Reader::TYPE_TEXT
          if block_given?
            yield
          end
      end
    end
  end

end