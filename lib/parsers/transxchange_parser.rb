require 'xml'
require 'zip/zip'
require 'test/unit'

class Parsers::TransxchangeParser

  include Test::Unit::Assertions
  attr_accessor :admin_area, :filename, :mode, :verbose, :skip_sections, :region_hash

  def initialize
    @file_count = 0
    @skip_sections = []
    @region_hash = {}
  end



  # Go through a directory and look for zip files in each directory. Get a stream from every
  # zip file found and pass it to parse_routes
  def parse_all_routes_in_zip(dirname, transport_mode=nil, load_run=nil, &block)
    Dir.glob(File.join(dirname, '*/')).each do |subdir|
      zips = Dir.glob(File.join(subdir, '*.zip'))
      zips.each do |zip|
        Zip::ZipFile.foreach(zip) do |txc_file|
          puts txc_file
          parse_routes(txc_file.get_input_stream(), transport_mode, load_run, txc_file.to_s, &block)
        end
      end
    end
  end

  def parse_index(filepath)
    @region_hash = {}
    tsv_data = File.read(filepath)
    first = true
    tsv_data.each do |row|
      row.chomp!
      if first
        first = false
        next
      end
      filename, region = row.split(" ", 2)
      @region_hash[filename.strip] = region.strip
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

  # Iterate through a set of files defined by file_pattern in random order, parsing the data from
  # them and producing a spreadsheet of some summary information
  def write_summary_info_file(file_pattern, outfile, verbose)
    filelist = Dir.glob(file_pattern)
    puts "Got #{filelist.size} files"
    outfile = File.open(outfile, 'w')
    sections = [:route_sections,
                :routes,
                :journey_pattern_sections,
                :vehicle_journeys,
                :operators,
                :services]
    headers = ['Filename',
               'Route Sections',
               'Routes',
               'Journey Pattern Sections',
               'Vehicle Journeys',
               'Operators',
               'Services',
               'Unexpected Elements']
    outfile.write(headers.join("\t")+"\n")
    filelist.sort_by { rand }.each do |filename|
      puts filename
      self.parse_data(filename, File.basename(filename), verbose) do |data|
        data_row = sections.map{ |section| data[section] ? data[section].size : 0 }
        outfile.write(([filename] + data_row + [data[:unexpected_elements].inspect]).join("\t")+"\n")
        @file_count += 1
        puts "Parsed #{@file_count} files"
      end
    end
    outfile.close()
  end

  def parse_all_tnds_routes(file_pattern, index_file_path, verbose, &block)
    filelist = Dir.glob(file_pattern)
    puts "Got #{filelist.size} files" if verbose
    self.parse_index(index_file_path)
    bus_mode = TransportMode.find_by_name('Bus')
    filelist.sort_by { rand }.each do |filename|
      sources = RouteSource.find(:all, :conditions => ['filename = ?', filename])
      next if ! sources.empty?
      region_name = self.region_hash[File.basename(filename)]
      region = Region.find_by_name(region_name)
      if ! region
        raise "Could not find region for #{filename} in index"
      end
      self.parse_routes(filename, default_transport_mode=bus_mode, nil, filename, verbose, region, &block)
    end
  end

  def write_route_names_file(file_pattern, outfile, verbose)
    filelist = Dir.glob(file_pattern)
    puts "Got #{filelist.size} files"
    outfile = File.open(outfile, 'w')

    headers = ['Filename',
               'Route number']
    outfile.write(headers.join("\t")+"\n")
    filelist.sort_by { rand }.each do |filename|
      puts filename
      self.parse_data(filename, File.basename(filename), verbose) do |data|
        data[:services].each do |service|
          if service[:standard_service][:journey_patterns].empty?
            puts "Skipping service #{service[:service_code]} - no standard service in this file" if verbose
            next
          end
          assert service[:lines].size == 1
          puts "#{service[:lines].first[:name]}"
          outfile.write(([filename, service[:lines].first[:name]]).join("\t")+"\n")
        end
        @file_count += 1
        puts "Parsed #{@file_count} files"
      end
    end
    outfile.close()
  end

  def parse_routes(input, default_transport_mode=nil, load_run=nil, filename=nil, verbose=true, region=nil, &block)
    stop_options = {:includes => {:stop_area_memberships => :stop_area}}
    missing = []
    missing_stops = {}
    parse_data(input, filename, verbose) do |data|
      journey_pattern_sections = data.delete(:journey_pattern_sections)
      operators_information = data.delete(:operators)
      services = data.delete(:services)
      services.each do |service|
        if service[:standard_service][:journey_patterns].empty?
          puts "Skipping service #{service[:service_code]} - no standard service in this file" if verbose
          next
        end
        lines = service.delete(:lines)
        assert lines.size == 1
        line = lines.first
        description = service.delete(:description)

        # Not currently used
        operating_period = service.delete(:operating_period)
        operating_profile = service.delete(:operating_profile)
        stop_requirements = service.delete(:stop_requirements)
        service_code = service.delete(:service_code)
        
        standard_service = service.delete(:standard_service)
        registered_operator_ref = service.delete(:registered_operator_ref)
        mode = service.delete(:mode)
        transport_mode = Operator.vehicle_mode_to_transport_mode(mode)
        if ! transport_mode
          raise "Could not map route mode #{mode} to a transport mode"
        end
        
        # Not currently used
        standard_service_origin = standard_service.delete(:origin)
        standard_service_destination = standard_service.delete(:destination)
          
        journey_patterns = standard_service.delete(:journey_patterns)
        route = Route.new(:number => line[:name],
                          :region => region, 
                          :transport_mode => transport_mode)
      
        journey_patterns.each do |id, journey_pattern|
          
          # not currently used
          direction = journey_pattern.delete(:direction)
          
          journey_pattern_id = journey_pattern.delete(:id)
          section_refs = journey_pattern.delete(:section_refs)
          jp = route.journey_patterns.build(:generation_low => CURRENT_GENERATION,
                                            :generation_high => CURRENT_GENERATION)
          segment_order = 0
          section_refs.each do |section_ref|
            section = journey_pattern_sections[section_ref]
            section[:timing_links].each do |timing_link|
              from_stop = Stop.find_by_code(timing_link[:from_info][:stop], stop_options)
              to_stop = Stop.find_by_code(timing_link[:to_info][:stop], stop_options)
              if !from_stop
                missing << timing_link[:from_info][:stop]
              end
              if !to_stop
                missing << timing_link[:to_info][:stop]
              end
              if (from_stop and to_stop)
                route_segment = jp.route_segments.build( :from_stop => from_stop,
                                                         :to_stop   => to_stop,
                                                         :route => route,
                                                         :segment_order => segment_order,
                                                         :generation_low => CURRENT_GENERATION,
                                                         :generation_high => CURRENT_GENERATION )
                segment_order += 1
                route_segment.set_stop_areas
              end
            end
          end
          if jp.route_segments.first
            jp.route_segments.first.from_terminus = true
          end
          if jp.route_segments.last
            jp.route_segments.last.to_terminus = true
          end
        end
        missing.each do |missing_stop_code|
          missing_stops = self.mark_stop_code_missing(missing_stops, missing_stop_code, route)
        end
        operator_information = operators[registered_operator_ref]
        operator_code = operator_information[:code]
        operators = Operator.find_all_by_nptdr_code(transport_mode, operator_code, region, route)
        operators.each do |operator|
          route.route_operators.build({ :operator => operator })
        end
        # apply each element of the data hash - alert if there are unused elements
        yield route
      end
      if load_run
        LoadRunCompletion.create!(:transport_mode => transport_mode,
                                  :load_type => 'routes',
                                  :name => load_run)
      end
      return missing_stops
    end
  end

  def parse_data(input, filename=nil, verbose=true, &block)
    @verbose = verbose
    if input.is_a?(String)
      @filename = input
      @reader = XML::Reader.file(input)
    else
      @filename = filename
      @reader = XML::Reader.io(input)
    end

    puts "starting..." if verbose
    @unexpected_elements = {}
    while @reader.read
      case @reader.node_type
        when XML::Reader::TYPE_ELEMENT
          handle_element
        when XML::Reader::TYPE_SIGNIFICANT_WHITESPACE
        when XML::Reader::TYPE_COMMENT
          handle_comment
        when XML::Reader::TYPE_END_ELEMENT
          handle_end_element
        else
          raise "Unhandled type: #{@reader.node_type} #{@reader.name}"
      end
    end

    data = { :route_sections => @route_sections,
             :routes => @routes,
             :journey_pattern_sections => @journey_pattern_sections,
             :operators => @operators,
             :services => @services,
             :vehicle_journeys => @vehicle_journeys,
             :unexpected_elements => @unexpected_elements.inspect }
    yield data
  end

  def handle_element
    ignored = [ 'TransXChange' ]
    handlers = { 'ServicedOrganisations'  => :handle_serviced_organisations,
                 'StopPoints'             => :handle_stop_points,
                 'RouteSections'          => :handle_route_sections,
                 'Routes'                 => :handle_routes,
                 'JourneyPatternSections' => :handle_journey_pattern_sections,
                 'Operators'              => :handle_operators,
                 'Services'               => :handle_services,
                 'VehicleJourneys'        => :handle_vehicle_journeys }

    if handlers.include?(@reader.name)
      self.send(handlers[@reader.name])
    elsif ignored.include?(@reader.name)
    else
      handle_unhandled("root", @reader.name)
    end
  end

  # ServicedOrganisations

  def handle_serviced_organisations
    puts "handling serviced_organisations" if verbose
    until_element_end(@reader.name)
  end

  # end ServicedOrganisations

  # StopPoints

  def handle_stop_points
    puts "handling stop points" if verbose
    until_element_end(@reader.name)
  end

  # end StopPoints

  # RouteSections

  def handle_route_sections
    puts "handling route sections" if verbose
    if @skip_sections.include?(:route_sections)
      until_element_end(@reader.name)
    else
      @route_sections = []
      handle_multiple(@reader.name, 'RouteSection', :handle_route_section)
    end
  end

  def handle_route_section
    @route_section = {}
    @route_section[:id] = get_attribute(@reader.name, 'id')
    @route_section[:route_links] = []
    handle_multiple(@reader.name, 'RouteLink', :handle_route_link)
    @route_sections << @route_section
  end

  def handle_route_link
    @route_link = {}
    @route_link[:id] = get_attribute(@reader.name, 'id')
    parent = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'From'
        @route_link[:from_info] = handle_route_link_terminus
      when 'To'
        @route_link[:to_info] = handle_route_link_terminus
      when 'Direction'
        @route_link[:direction] = get_element_text('Direction')
      when 'Distance'
        @route_link[:distance] = get_element_text('Distance')
      when 'Track'
        handle_track
      else
        handle_unhandled(parent, @reader.name)
      end
    end
    @route_section[:route_links] << @route_link
  end

  def handle_track
    until_element_end(@reader.name)
  end

  def handle_route_link_terminus
    terminus_info = {}
    terminus_name = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'StopPointRef'
        terminus_info[:stop] = get_element_text('StopPointRef').strip
      else
        handle_unhandled(terminus_name, @reader.name)
      end
    end
    return terminus_info
  end

  # end RouteSections

  # Routes

  def handle_routes
    puts "handling routes" if verbose
    if @skip_sections.include?(:routes)
      until_element_end(@reader.name)
    else
      @routes = []
      handle_multiple(@reader.name, 'Route', :handle_route)
    end
  end

  def handle_route
    @route = {}
    @route[:id] = get_attribute(@reader.name, 'id')
    parent = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'PrivateCode'
        @route[:private_code] = get_element_text('PrivateCode')
      when 'Description'
        @route[:description] = get_element_text('Description')
      when 'RouteSectionRef'
        @route[:route_section_ref] = get_element_text('RouteSectionRef')
      else
        handle_unhandled(parent, @reader.name)
      end
    end
    @routes << @route
  end

  # end Routes

  # JourneyPatternSections

  def handle_journey_pattern_sections
    puts "handling journey pattern sections" if verbose
    if @skip_sections.include?(:journey_pattern_sections)
      until_element_end(@reader.name)
    else
      @journey_pattern_sections = {}
      handle_multiple(@reader.name, 'JourneyPatternSection', :handle_journey_pattern_section)
    end
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
    timing_link[:id] = get_attribute(@reader.name, 'id')
    parent = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'From'
        timing_link[:from_info] = handle_timing_link_terminus
      when 'To'
        timing_link[:to_info] = handle_timing_link_terminus
      when 'RunTime'
        timing_link[:runtime] = get_element_text('RunTime')
      when 'RouteLinkRef'
        timing_link[:route_link_ref] = get_element_text('RouteLinkRef')
      when 'Direction'
        timing_link[:direction] = get_element_text('Direction')
      else
        handle_unhandled(parent, @reader.name)
      end
    end
    @journey_pattern_section[:timing_links] << timing_link
  end

  def handle_timing_link_terminus
    terminus_info = {}
    parent = @reader.name
    terminus_info[:sequence_number] = get_attribute(@reader.name, 'sequenceNumber', required=false)
    until_element_end(@reader.name) do
      case @reader.name
      when 'StopPointRef'
        terminus_info[:stop] = get_element_text('StopPointRef').strip
      when 'WaitTime'
        terminus_info[:wait_time] = get_element_text('WaitTime')
      when 'TimingStatus'
        terminus_info[:timing_status] = get_element_text('TimingStatus')
      when 'Activity'
        terminus_info[:activity] = get_element_text('Activity')
      else
        handle_unhandled(parent, @reader.name)
      end
    end
    return terminus_info
  end

  # end JourneyPatternSections

  # Operators

  def handle_operators
    puts "handling operators" if verbose
    if @skip_sections.include?(:operators)
      until_element_end(@reader.name)
    else
      @operators = {}
      handle_multiple(@reader.name, 'Operator', :handle_operator)
    end
  end

  def handle_operator
    operator_info = {}
    operator_info[:id] = get_attribute(@reader.name, 'id')
    parent = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'OperatorCode'
        operator_info[:code] = get_element_text('OperatorCode')
      when 'OperatorShortName'
        operator_info[:short_name] = get_element_text('OperatorShortName')
      when 'OperatorNameOnLicence'
        operator_info[:name_on_license] = get_element_text('OperatorNameOnLicence')
      when 'TradingName'
        operator_info[:trading_name] = get_element_text('TradingName')
      when 'EnquiryTelephoneNumber'
        handle_telephone_number
      when 'ContactTelephoneNumber'
        handle_telephone_number
      when 'OperatorAddresses'
        until_element_end(@reader.name) do
          case @reader.name
          when 'CorrespondenceAddress'
            handle_correspondence_address
          else
            handle_unhandled('OperatorAddress', @reader.name)
          end
        end
      else
        handle_unhandled(parent, @reader.name)
      end
    end
    @operators[operator_info[:id]] = operator_info
  end

  def handle_correspondence_address
    until_element_end(@reader.name)
  end

  def handle_telephone_number
    until_element_end(@reader.name)
  end

  # end Operators

  # Services
  def handle_services
    puts "handling services" if verbose
    if @skip_sections.include?(:services)
      until_element_end(@reader.name)
    else
      @services = []
      handle_multiple(@reader.name, 'Service', :handle_service)
      if @services.all?{ |service| service[:standard_service][:journey_patterns].empty? }
        raise "No standard service has been defined"
      end
    end
  end

  def handle_service
    @service = {:lines => [],
                :operating_period => {},
                :operating_profile => {:regular_day_type => {},
                                       :bank_holiday_operation => {},
                                       :special_days_operation => {}},
                :standard_service => {:journey_patterns => {}}}
    parent = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'ServiceCode'
        @service[:service_code] = get_element_text('ServiceCode')
      when 'PrivateCode'
        @service[:private_code] = get_element_text('PrivateCode')
      when 'Lines'
        handle_multiple(@reader.name, 'Line', :handle_line)
        if @service[:lines].size > 1
          raise "More than one line for a service"
        end
      when 'OperatingPeriod'
        handle_operating_period
      when 'OperatingProfile'
        handle_operating_profile
      when 'RegisteredOperatorRef'
        @service[:registered_operator_ref] = get_element_text('RegisteredOperatorRef')
      when 'AssociatedOperators'
        handle_associated_operators
      when 'StopRequirements'
        handle_stop_requirements
      when 'StandardService'
        handle_standard_service
      when 'Description'
        @service[:description] = get_element_text('Description')
      when 'Mode'
        @service[:mode] = get_element_text('Mode')
      when 'ToBeMarketedWith'
        until_element_end(@reader.name)
      else
        handle_unhandled(parent, @reader.name)
      end
    end
    @services << @service
  end

  def handle_associated_operators
    @service[:associated_operators] = []
    parent = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'OperatorRef'
        @service[:associated_operators] << get_element_text('OperatorRef')
      else
        handle_unhandled(parent,@reader.name)
      end
    end
  end

  def handle_line
    line_info = {}
    parent = @reader.name
    line_info[:id] = get_attribute(@reader.name, 'id')
    until_element_end(@reader.name) do
      case @reader.name
      when 'LineName'
        line_info[:name] = get_element_text('LineName')
      else
        handle_unhandled(parent, @reader.name)
      end
    end
    @service[:lines] << line_info
  end

  def handle_operating_period
    parent = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'StartDate'
        @service[:operating_period][:start_date] = get_element_text('StartDate')
      when 'EndDate'
        @service[:operating_period][:end_date] = get_element_text('EndDate')
      else
        handle_unhandled(parent, @reader.name)
      end
    end
  end

  def handle_operating_profile
    until_element_end(@reader.name)
  end

  def handle_stop_requirements
    parent = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'NoNewStopsRequired'
        @service[:stop_requirements] = :no_new_stops_required
      else
        handle_unhandled(parent, @reader.name)
      end
    end
  end

  def handle_standard_service
    parent = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'Origin'
        @service[:standard_service][:origin] = get_element_text('Origin')
      when 'Destination'
        @service[:standard_service][:destination] = get_element_text('Destination')
      when 'JourneyPattern'
        journey_pattern = handle_journey_pattern
        @service[:standard_service][:journey_patterns][journey_pattern[:id]] = journey_pattern
      when 'UseAllStopPoints'
        @service[:standard_service][:use_all_stop_points] = get_element_text('UseAllStopPoints')
      else
        handle_unhandled(parent, @reader.name)
      end
    end
  end

  def handle_journey_pattern
    journey_pattern = {}
    journey_pattern[:id] = get_attribute(@reader.name, 'id')
    journey_pattern[:section_refs] = []
    parent = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'DestinationDisplay'
        journey_pattern[:destination_display] = get_element_text('DestinationDisplay')
      when 'Direction'
        journey_pattern[:direction] = get_element_text('Direction')
      when 'JourneyPatternSectionRefs'
        journey_pattern[:section_refs] << get_element_text('JourneyPatternSectionRefs')
      when 'RouteRef'
        journey_pattern[:route_ref] = get_element_text('RouteRef')
      when 'Operational'
        handle_operational
      else
        handle_unhandled(parent, @reader.name)
      end
    end
    return journey_pattern
  end

  # end Services

  # VehicleJourneys

  def handle_vehicle_journeys
    puts "handling vehicle journeys" if verbose
    if @skip_sections.include?(:vehicle_journeys)
      until_element_end(@reader.name)
    else
      @vehicle_journeys = []
      parent = @reader.name
      until_element_end(@reader.name) do
        case @reader.name
        when 'VehicleJourney'
          handle_vehicle_journey
        else
          handle_unhandled(parent, @reader.name)
        end
      end
    end
  end

  def handle_vehicle_journey
    @vehicle_journey = {}
    parent = @reader.name
    until_element_end(@reader.name) do
      case @reader.name
      when 'PrivateCode'
        @vehicle_journey[:private_code] =  get_element_text('PrivateCode')
      when 'VehicleJourneyCode'
        @vehicle_journey[:vehicle_journey_code] =  get_element_text('VehicleJourneyCode')
      when 'ServiceRef'
        @vehicle_journey[:service_ref] = get_element_text('ServiceRef')
      when 'LineRef'
        @vehicle_journey[:line_ref] = get_element_text('LineRef')
      when 'JourneyPatternRef'
        @vehicle_journey[:journey_pattern_ref] = get_element_text('JourneyPatternRef')
      when 'Direction'
        @vehicle_journey[:direction] = get_element_text('Direction')
      when 'DepartureTime'
        @vehicle_journey[:departure_time] = get_element_text('DepartureTime')
      when 'DestinationDisplay'
        @vehicle_journey[:destination_display] = get_element_text('DestinationDisplay')
      when 'VehicleJourneyTimingLink'
        handle_vehicle_journey_timing_link
      when 'Operational'
        handle_operational
      when 'OperatingProfile'
        handle_operating_profile
      when 'OperatorRef'
        @vehicle_journey[:operator_ref] = get_element_text('OperatorRef')
      when 'StartDeadRun'
        until_element_end(@reader.name)
      when 'EndDeadRun'
        until_element_end(@reader.name)
      else
        handle_unhandled(parent, @reader.name)
      end
    end
    @vehicle_journeys << @vehicle_journey
  end

  def handle_vehicle_journey_timing_link
    until_element_end(@reader.name)
  end

  def handle_operational
    until_element_end(@reader.name)
  end

  # end VehicleJourneys

  def handle_multiple(element_name, inner_element, handler)
    until_element_end(element_name) do
      if (inner_element.kind_of?(Array) && inner_element.include?(@reader.name)) || @reader.name == inner_element
        self.send(handler)
      else
        handle_unhandled(element_name, @reader.name)
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

  def get_attribute(element_name, attribute, required=true)
    if ! @reader.has_attributes? && required
      raise "No attributes in #{element_name}"
    end
    return @reader[attribute]
  end

  # yield all the elements and text until this element closes, ignore element ends and whitespace
  def until_element_end(name)
    return if @reader.empty_element?
    if ! block_given?
      puts "Skipping #{name} and all children" if verbose
    end
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

  def handle_end_element
    if ! @reader.name == 'TransXChange'
      raise "Unexpected end element #{@reader.name}"
    end
  end

  def handle_comment
    puts "Comment: #{@reader.value}" if verbose
  end

  def handle_unhandled(parent, element)
    @unexpected_elements[element] = 0 if @unexpected_elements[element].nil?
    @unexpected_elements[element] += 1
  end
end