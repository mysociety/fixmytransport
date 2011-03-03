require 'libxml'
require 'zip/zip'
require 'test/unit'

class Parsers::TransxchangeParser

  include LibXML
  include Test::Unit::Assertions
  
  def initialize
  end
  
  # Go through a directory and look for zip files in each directory. Get a stream from every 
  # zip file found and pass it to parse_routes
  def parse_all_routes(dirname)
    Dir.glob(File.join(dirname, '*/')).each do |subdir|
      zips = Dir.glob(File.join(subdir, '*.zip'))
      zips.each do |zip|
        Zip::ZipFile.foreach(zip) do |txc_file|
          puts txc_file
          parse_routes(txc_file.get_input_stream()) 
        end
      end
    end
  end
  
  def parse_routes(input)
    if input.is_a?(String)
      @reader = XML::Reader.file(input)
    else
      @reader = XML::Reader.io(input)
    end
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
    @journey_pattern_sections = []
    handle_multiple(@reader.name, 'JourneyPatternSection', :handle_journey_pattern_section)
  end
  
  def handle_journey_pattern_section
    @journey_pattern_section = {}
    @journey_pattern_section[:id] = get_attribute(@reader.name, 'id')
    handle_multiple(@reader.name, 'JourneyPatternTimingLink', :handle_timing_link)
    @journey_pattern_sections << @journey_pattern_section
  end
  
  def handle_timing_link
    until_element_end(@reader.name) do
      case @reader.name 
      when 'From'
        from_info = handle_link_terminus
      when 'To'
        to_info = handle_link_terminus
      when 'RunTime'
        get_element_text('RunTime')
      else 
        raise "Unexpected element in JourneyPatternTimingLink: #{@reader.name}"
      end
    end
  end
  
  def handle_link_terminus
    terminus_info = {}
    until_element_end(@reader.name) do 
      case @reader.name
      when 'StopPointRef'
        terminus_info[:stop] = get_element_text('StopPointRef')
      when 'WaitTime'
        terminus_info[:wait_time] = get_element_text('WaitTime')
      when 'TimingStatus'
        terminus_info[:timing_status] = get_element_text('TimingStatus')
      when 'Activity'
        terminus_info[:activity] = get_element_text('Activity')
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
    puts "-----------service--------------"
    @route = Route.new
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
    puts @route.inspect
    puts @lines.inspect
    puts @journey_patterns.inspect
    @route = Route.new
  end
  
  def handle_stop_requirements
    until_element_end(@reader.name) 
  end
    
  def handle_standard_service
    @journey_patterns = []
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
  end
  
  def handle_journey_pattern
    journey_pattern = {}
    journey_pattern[:id] = get_attribute(@reader.name, 'id')
    until_element_end(@reader.name) do 
      case @reader.name
      when 'DestinationDisplay'
        journey_pattern[:destination_display] = get_element_text('DestinationDisplay')
      when 'Direction'
        journey_pattern[:direction] = get_element_text('Direction')
      when 'JourneyPatternSectionRefs'
        journey_pattern[:section_refs] = get_element_text('JourneyPatternSectionRefs')
      else
        raise "Unexpected element in JourneyPattern: #{@reader.name}"
      end
    end
    @journey_patterns << journey_pattern
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