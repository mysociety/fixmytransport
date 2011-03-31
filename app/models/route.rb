# == Schema Information
# Schema version: 20100707152350
#
# Table name: routes
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  number            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  type              :string(255)
#  name              :string(255)
#  region_id         :integer
#  cached_slug       :string(255)
#  operator_code     :string(255)
#  loaded            :boolean
#

class Route < ActiveRecord::Base
  extend ActiveSupport::Memoizable

  has_many :route_sub_routes
  has_many :sub_routes, :through => :route_sub_routes
  has_many :route_operators, :dependent => :destroy, :uniq => true
  has_many :operators, :through => :route_operators, :uniq => true
  has_many :journey_patterns, :dependent => :destroy, :order => 'id asc'
  has_many :route_segments, :dependent => :destroy, :order => 'id asc'
  has_many :from_stops, :through => :route_segments, :class_name => 'Stop'
  has_many :to_stops, :through => :route_segments, :class_name => 'Stop'
  belongs_to :transport_mode
  has_many :campaigns, :as => :location, :order => 'created_at desc'
  has_many :problems, :as => :location, :order => 'created_at desc'
  has_many :route_localities, :dependent => :destroy
  has_many :localities, :through => :route_localities
  belongs_to :region
  has_many :route_source_admin_areas, :dependent => :destroy
  has_many :source_admin_areas, :through => :route_source_admin_areas, :class_name => 'AdminArea'
  accepts_nested_attributes_for :route_operators, :allow_destroy => true, :reject_if => :route_operator_invalid
  accepts_nested_attributes_for :route_segments, :allow_destroy => true, :reject_if => :route_segment_invalid
  validates_presence_of :number, :transport_mode_id
  validates_presence_of :region_id, :if => :loaded?
  cattr_reader :per_page
  has_friendly_id :short_name, :use_slug => true, :scope => :region
  has_paper_trail
  attr_accessor :show_as_point, :journey_pattern_data
  before_save :cache_route_description, :cache_route_coords
  is_route_or_sub_route

  @@per_page = 20

  # instance methods

  def route_operator_invalid(attributes)
    (attributes['_add'] != "1" and attributes['_destroy'] != "1") or attributes['operator_id'].blank?
  end

  def route_segment_invalid(attributes)
    (attributes['_add'] != "1" and attributes['_destroy'] != "1") or \
    attributes['from_stop_id'].blank? or attributes['to_stop_id'].blank?
  end

  def region_name
    region ? region.name : nil
  end

  def stop_codes
    stops.map{ |stop| stop.atco_code or stop.other_code }.uniq
  end

  def stop_area_codes
    stop_areas = stops.map{ |stop| stop.stop_areas }.flatten
    stop_areas.map{ |stop_area| stop_area.code }.uniq
  end

  def transport_mode_name
    transport_mode.name
  end

  def area(lowercase=false)
    area = ''
    area_list = areas(all=false)
    if area_list.size > 1
      area = "Between #{area_list.to_sentence}"
    else
      area = "In #{area_list.first}" if !area_list.empty?
    end
    if !area.blank? && lowercase
      area[0] = area.first.downcase
    end
    return area
  end

  def areas(all=true)
    if all or terminuses.empty?
      route_stop_list = stops
    else
      route_stop_list = terminuses
    end
    areas = route_stop_list.map do |stop|
      next if ! stop.locality
      if stop.locality.parents.empty?
        stop.locality.name
      else
        stop.locality.parents.map{ |parent_locality| parent_locality.name }
      end
    end.flatten.uniq
    areas
  end

  def description
    return cached_description if cached_description
    "#{name(from_stop=nil, short=true)} #{area(lowercase=true)}"
  end

  def short_name
    name(from_stop=nil, short=true)
  end

  def full_name
    "#{name} route"
  end

  def name(from_stop=nil, short=false)
    return self[:name] if !self[:name].blank?
    default_name = "#{number}"
    if from_stop
      return default_name
    else
      if short
        return default_name
      else
       return "#{transport_mode_name} #{default_name}"
      end
    end
  end

  def points
    stops_or_stations
  end

  def transport_modes
    [transport_mode]
  end

  def default_journey
    journey_patterns.sort{ |a,b| a.route_segments.count <=> b.route_segments.count }.last
  end

  def stops_or_stations
    default_journey.route_segments.map do |route_segment|
      if route_segment.from_stop_area
        from = route_segment.from_stop_area
      else
        from = route_segment.from_stop
      end
      if route_segment.to_stop_area
        to = route_segment.to_stop_area
      else
        to = route_segment.to_stop
      end
      [from, to]
    end.flatten.uniq
  end

  def stops
    journey_patterns.map{ |jp| jp.route_segments.map{ |route_segment| [route_segment.from_stop, route_segment.to_stop] }}.flatten.uniq
  end

  def next_stops(current)
    if current.is_a? StopArea
      outgoing_segments = route_segments.select{ |route_segment| route_segment.from_stop_area_id == current.id }
    else
      outgoing_segments = route_segments.select{ |route_segment| route_segment.from_stop_id == current.id }
    end
    next_stops = outgoing_segments.map do |route_segment|
      route_segment.to_stop_area ? route_segment.to_stop_area : route_segment.to_stop
    end
    next_stops.uniq
  end

  def previous_stops(current)
    if current.is_a? StopArea
      incoming_segments = route_segments.select{ |route_segment| route_segment.to_stop_area_id == current.id }
    else
      incoming_segments = route_segments.select{ |route_segment| route_segment.to_stop_id == current.id }
    end
    previous_stops = incoming_segments.map do |route_segment|
      route_segment.from_stop_area ? route_segment.from_stop_area : route_segment.from_stop
    end
    previous_stops.uniq - next_stops(current)
  end

  def terminuses
    segments = journey_patterns.map{ |journey_pattern| journey_pattern.route_segments }.flatten
    from_terminuses = segments.select{ |route_segment| route_segment.from_terminus? }
    to_terminuses = segments.select{ |route_segment| route_segment.to_terminus? }
    from_terminuses = from_terminuses.map do |segment|
      segment.from_stop_area ? segment.from_stop_area : segment.from_stop
    end
    to_terminuses = to_terminuses.map do |segment|
      segment.to_stop_area ? segment.to_stop_area : segment.to_stop
    end
    terminuses = from_terminuses + to_terminuses
    terminuses.uniq
  end
  memoize :terminuses

  def description_with_operators
    text = "#{description}"
    if !operators.empty?
      text += " (#{operator_text})"
    end
    text
  end

  def operator_text
    operators.map{ |operator| operator.name }.to_sentence
  end

  def responsible_organizations
    operators
  end

  def councils_responsible?
    false
  end

  def pte_responsible?
    false
  end

  def operators_responsible?
    true
  end

  def sub_route_problems
    problem_list = sub_routes.map{ |sub_route| sub_route.problems }
    if operators
      problem_list = problem_list.select{ |problem| operators.include?(problem.operator) }
    end
    problem_list
  end

  def cache_route_description
    self.cached_description = self.description
  end

  def cache_route_coords
    return if stops.empty?
    lons = self.stops.map{ |element| element.lon }
    lats = self.stops.map{ |element| element.lat }
    lon = lons.min + ((lons.max - lons.min)/2)
    lat = lats.min + ((lats.max - lats.min)/2)
    self.lat = lat
    self.lon = lon
  end

  # class methods

  def self.full_find(id, scope)
    find(id,
         :scope => scope,
         :include => [{ :route_segments => [:to_stop => :locality, :from_stop => :locality] },
                      { :route_operators => :operator }])

  end

  # Return routes with this number and transport mode that have a stop or stop area in common with
  # the route given
  def self.find_all_by_number_and_common_stop(new_route, any_admin_area=false)
    stop_codes = new_route.stop_codes
    # do we think we know the operator for this route? If so, return any route with the same operator that
    # meets our other criteria. Otherwise, only return operators with the same operator code from the same
    # admin area
    if new_route.route_operators.size == 1
      operator_clause = "AND route_operators.operator_id = ? "
      operator_params = [new_route.route_operators.first.operator_id]
    else
      source_admin_area = new_route.route_source_admin_areas.first
      operator_clauses = []
      operator_params = []
      # did this come from an admin area, or from the national routes data?
      if ! any_admin_area
        if source_admin_area.source_admin_area_id
          operator_clauses << "AND route_source_admin_areas.source_admin_area_id = ?"
          operator_params << source_admin_area.source_admin_area_id
        else
          operator_clauses << "AND route_source_admin_areas.source_admin_area_id is NULL"
        end
      end
      operator_clauses << "AND route_source_admin_areas.operator_code = ? "
      operator_params << new_route.route_source_admin_areas.first.operator_code
      operator_clause = operator_clauses.join(" ")
    end

    id_clause = ''
    id_params = []
    if new_route.id
      id_clause = " AND routes.id != ?"
      id_params = [new_route.id]
    end
    stop_area_codes = new_route.stop_area_codes
    condition_string = "number = ? AND transport_mode_id = ? #{operator_clause} #{id_clause}"
    conditions = [condition_string, new_route.number, new_route.transport_mode.id]
    conditions += operator_params
    conditions += id_params
    routes = Route.find(:all, :conditions => conditions,
                        :include => [ {:journey_patterns => {:route_segments => [:from_stop, :to_stop] }},
                                       :route_operators,
                                       :route_source_admin_areas ])
    routes_with_same_stops = []

    routes.each do |route|
      route_stop_codes = route.stop_codes
      stop_codes_in_both = (stop_codes & route_stop_codes)
      if stop_codes_in_both.size > 0
        routes_with_same_stops << route
        next
      end
      route_stop_area_codes = route.stop_area_codes
      stop_area_codes_in_both = (stop_area_codes & route_stop_area_codes)
      if stop_area_codes_in_both.size > 0
        routes_with_same_stops << route
      end
    end
    # requery fresh objects as the joins we used in the find query may result in only some associations
    # being eagerly loaded
    Route.find(routes_with_same_stops.map{ |route| route.id })
  end

  # Accepts an array of stops or an array of arrays of locations (stops or stop areas) as first parameter.
  # If passed the latter, will find routes that pass through at least one location in
  # each array. Additional params to constrain the search can be passed as options.
  def self.find_all_by_locations(stops_or_stop_areas, options)
    from_terminus_clause = ''
    to_terminus_clause = ''
    params = []
    include_params = []
    condition_string = ''
    if options[:transport_modes]
      condition_string += 'transport_mode_id in (?)'
      params << options[:transport_modes]
    end

    if options[:operator_id]
      condition_string += " AND route_operators.operator_id = ? "
      params << options[:operator_id]
      include_params << :route_operators
    end

    if options[:source_admin_area]
      condition_string += " AND route_source_admin_areas.operator_code = ?
                            AND route_source_admin_areas.source_admin_area_id = ?"
      params << options[:source_admin_area].operator_code
      params << options[:source_admin_area].source_admin_area_id
      include_params << :route_source_admin_areas
    end

    include_params << :route_segments
    joins = ''
    last_index = nil
    stops_or_stop_areas.each_with_index do |item,index|
      if options[:as_terminus]
        from_terminus_clause = "rs#{index}.from_terminus = 't' and"
        to_terminus_clause = "rs#{index}.to_terminus = 't' and"
      end
      if item.is_a? Array
        stop_id_criteria = "in (?)"
        if item.all?{ |location| location.is_a?(StopArea) }
          location_key = 'stop_area_id'
        else
          location_key = 'stop_id'
        end
      else
        stop_id_criteria = "= ?"
        if item.is_a?(StopArea)
          location_key = 'stop_area_id'
        else
          location_key = 'stop_id'
        end
      end
      joins += " inner join route_segments rs#{index} on routes.id = rs#{index}.route_id"
      condition_string += " and ((#{from_terminus_clause} rs#{index}.from_#{location_key} #{stop_id_criteria})"
      condition_string += " or (#{to_terminus_clause} rs#{index}.to_#{location_key} #{stop_id_criteria}))"
      params << item
      params << item
      if last_index
        condition_string += " and rs#{index}.journey_pattern_id = rs#{last_index}.journey_pattern_id"
      end
      last_index = index
    end
    conditions = [condition_string] + params
    routes = find(:all, :select => "distinct routes.id",
                        :joins => joins,
                        :conditions => conditions,
                        :include => include_params,
                        :limit => options[:limit]).uniq
    # The joins in the query above cause it to return instances with missing segments -
    # remap to clean route objects
    Route.find(routes.map{ |route| route.id })
  end

  def self.find_existing_routes(new_route)
    find_all_by_number_and_common_stop(new_route)
  end

  def self.find_without_operators(options={})
    if !options.has_key?(:order)
      options[:order] = 'number ASC'
    end
    query = 'id not in (SELECT route_id FROM route_operators)'
    params = []
    if options[:operator_code]
      query += " AND operator_code = ?"
      params << options[:operator_code]
    end
    params = [query] + params
    find(:all, :conditions => params,
         :limit => options[:limit],
         :order => options[:order])
  end

  def self.count_without_operators(options={})
    count(:conditions => ['id not in (SELECT route_id FROM route_operators)'])
  end

  # finds operator codes that are associated with routes
  # where the code isn't associated with an operator,
  # and the route doesn't have an operator
  def self.find_codes_without_operators(options={})
    query = "SELECT operator_code, cnt FROM
               (SELECT operator_code, count(*) as cnt
                FROM routes
                WHERE id not in
                  (SELECT route_id
                   FROM route_operators)
                GROUP BY operator_code)
                 as tmp
             ORDER BY cnt desc"
    if options[:limit]
      query += " LIMIT #{options[:limit]}"
    end
    connection.select_rows(query)
  end

  def self.count_codes_without_operators()
    count(:select => 'distinct operator_code',
          :conditions => ['id not in (SELECT route_id from route_operators)'])
  end

  # Return train routes by the same operator that have the same terminuses
  def Route.find_existing_train_routes(new_route)
    operator_code = new_route.operator_code
    options = { :as_terminus => true,
                :transport_modes => [new_route.transport_mode_id] }
    if new_route.route_operators.size == 1
      options[:operator_id] = new_route.route_operators.first.operator_id
    else
      source_admin_area = new_route.route_source_admin_areas.first
      options[:source_admin_area => source_admin_area]
    end
    found_routes = []
    new_route.journey_patterns.each do |journey_pattern|
      from_terminus_segments = journey_pattern.route_segments.select{ |route_segment| route_segment.from_terminus? }
      to_terminus_segments = journey_pattern.route_segments.select{ |route_segment| route_segment.to_terminus? }
      from_terminuses = from_terminus_segments.map{ |route_segment| route_segment.from_stop_area }
      to_terminuses = to_terminus_segments.map{ |route_segment| route_segment.to_stop_area }
      found_routes << Route.find_all_by_locations([from_terminuses, to_terminuses], options)
    end
    found_routes.flatten.uniq
  end

  def self.get_terminuses(route_name)
    if terminus_match = /^(.*)\sto\s(.*)$/.match(route_name)
      return [terminus_match[1], terminus_match[2]]
    else
      return nil
    end
  end

  def self.add!(route, verbose=false)
    puts "Adding #{route.number}" if verbose
    existing_routes = find_existing(route)
    if existing_routes.empty?
      route.save!
      return route
    end
    puts "got existing" if verbose
    original = existing_routes.first
    duplicates = existing_routes - [original]
    puts "merging new" if verbose
    merge_duplicate_route(route, original)
    duplicates.each do |duplicate|
      original = Route.find(original.id)
      puts "merging duplicates" if verbose
      if find_existing(duplicate).include? original
        merge_duplicate_route(duplicate, original)
      end
    end
  end

  def self.merge!(merge_to, routes)
    transaction do
      routes.each do |route|
        next if route == merge_to
        merge_duplicate_route(route, merge_to)
      end
    end
  end

  def self.merge_duplicate_route(duplicate, original)
    raise "Can't merge route with campaigns: #{duplicate.inspect}" if !duplicate.campaigns.empty?
    raise "Can't merge route with problems: #{duplicate.inspect}" if !duplicate.problems.empty?
    duplicate.route_operators.each do |route_operator|
      if ! original.route_operators.detect { |existing| existing.operator == route_operator.operator }
        original.route_operators.build(:operator => route_operator.operator)
      end
    end
    duplicate.route_source_admin_areas.each do |route_source_admin_area|
      if ! original.route_source_admin_areas.detect{ |existing| existing.source_admin_area == route_source_admin_area.source_admin_area }
        original.route_source_admin_areas.build(:source_admin_area => route_source_admin_area.source_admin_area,
                                                :operator_code => route_source_admin_area.operator_code)
      end
    end

    duplicate.journey_patterns.each do |journey_pattern|
      matched = false
      original.journey_patterns.each do |original_journey_pattern|
        if journey_pattern.identical_segments?(original_journey_pattern)
          matched = true
        end
      end
      if ! matched
        new_journey_pattern = original.journey_patterns.build(:destination => journey_pattern.destination)
        journey_pattern.route_segments.each do |route_segment|
          new_journey_pattern.route_segments.build(:from_stop => route_segment.from_stop,
                                                   :to_stop => route_segment.to_stop,
                                                   :from_terminus => route_segment.from_terminus,
                                                   :to_terminus => route_segment.to_terminus,
                                                   :segment_order => route_segment.segment_order,
                                                   :route => original)
        end
      end

    end
    duplicate.destroy unless duplicate.new_record?
    original.save!
  end


end
