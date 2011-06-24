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
  belongs_to :default_journey, :class_name => 'JourneyPattern'
  has_many :route_source_admin_areas, :dependent => :destroy
  has_many :source_admin_areas, :through => :route_source_admin_areas, :class_name => 'AdminArea'
  accepts_nested_attributes_for :route_operators, :allow_destroy => true, :reject_if => :route_operator_invalid
  accepts_nested_attributes_for :journey_patterns, :allow_destroy => true, :reject_if => :journey_pattern_invalid
  validates_presence_of :number, :transport_mode_id
  validates_presence_of :region_id, :if => :loaded?
  cattr_reader :per_page
  has_friendly_id :short_name, :use_slug => true, :scope => :region
  has_paper_trail
  attr_accessor :show_as_point, :journey_pattern_data
  before_save :cache_route_coords, :generate_default_journey, :cache_area, :cache_description
  is_route_or_sub_route
  is_location

  @@per_page = 20

  # instance methods

  def route_operator_invalid(attributes)
    (attributes['_add'] != "1" and attributes['_destroy'] != "1") or attributes['operator_id'].blank?
  end

  def journey_pattern_invalid(attributes)
    # ignore a journey pattern that doesn't have an _add attribute or
    # that's new but doesn't have any real route segments (just the new segment template)
    (attributes['_add'] != "1") || \
    (attributes['id'].blank? && (attributes['route_segments_attributes'].nil? || \
     attributes['route_segments_attributes'].keys.all?{|key| key == 'new_route_segment' }))
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

  def cache_area
    self.cached_area = nil
    self.cached_area = self.area
  end

  def description
    return cached_description if cached_description
    "#{name(from_stop=nil, short=true)} #{area(lowercase=true)}"
  end

  def area(lowercase=false)
    if cached_area
      area = cached_area
    else
      area = ''
      area_list = areas(all=false)
      if area_list.size > 1
        area = "Between #{area_list.to_sentence}"
      else
        area = "In #{area_list.first}" if !area_list.empty?
      end
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
    "#{name(from_stop=nil, short=true)} #{area(lowercase=true)}"
  end

  def short_name
    name(from_stop=nil, short=true)
  end
  memoize :short_name

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
    all_locations
  end

  def transport_modes
    [transport_mode]
  end

  def all_locations
    _get_locations
  end
  memoize :all_locations

  def _get_locations(terminuses_only=false)
    if terminuses_only
      from_terminus_clause = "AND from_terminus = ?"
      to_terminus_clause = "AND to_terminus = ?"
      params = [self.id, true, self.id, true]
    else
      from_terminus_clause = ''
      to_terminus_clause = ''
      params = [self.id, self.id]
    end
    stop_sql = "id in ((SELECT from_stop_id
                        FROM route_segments
                        WHERE route_id = ?
                        #{from_terminus_clause}
                        AND from_stop_area_id is null)
                      UNION
                       (SELECT to_stop_id
                        FROM route_segments
                        WHERE route_id = ?
                        #{to_terminus_clause}
                        AND to_stop_area_id is null))"

    stop_conditions = [stop_sql] + params
    stops = Stop.find(:all, :conditions => stop_conditions,
                            :include => :locality)
    stop_area_sql = "id in ((SELECT from_stop_area_id
                             FROM route_segments
                             WHERE route_id = ?
                             #{from_terminus_clause})
                           UNION
                            (SELECT to_stop_area_id
                             FROM route_segments
                             WHERE route_id = ?
                             #{to_terminus_clause}))"
    stop_area_conditions = [stop_area_sql] + params
    stop_areas = StopArea.find(:all, :conditions => stop_area_conditions,
                            :include => :locality)
    return stops + stop_areas
  end

  def default_journey_locations
    if ! default_journey
      generate_default_journey
    end
    segments = default_journey.route_segments
    stop_ids = Hash.new { |hash, key| hash[key] = [] }
    stop_area_ids = Hash.new { |hash, key| hash[key] = [] }
    segments.each_with_index do |route_segment, index|
      if route_segment.from_stop_area_id
        stop_area_ids[route_segment.from_stop_area_id] << index
      else
        stop_ids[route_segment.from_stop_id] << index
      end
    end
    if segments.last.to_stop_area_id
      stop_area_ids[segments.last.to_stop_area_id] << segments.length
    else
      stop_ids[segments.last.to_stop_id] << segments.length
    end
    locations = []
    stops = Stop.find(:all, :conditions => ['id in (?)', stop_ids.keys],
                            :include => :locality)
    stops.each do |stop|
      stop_ids[stop.id].each do |index|
        locations[index] = stop
      end
    end
    stop_areas = StopArea.find(:all, :conditions => ['id in (?)', stop_area_ids.keys],
                                     :include => :locality)
    stop_areas.each do |stop_area|
      stop_area_ids[stop_area.id].each do |index|
        locations[index] = stop_area
      end
    end
    locations
  end

  def stops
    if new_record?
      stops = journey_patterns.map{ |jp| jp.route_segments.map{ |route_segment| [route_segment.from_stop, route_segment.to_stop] }}.flatten.uniq
    else
      stops = Stop.find(:all, :conditions => ["id in ((SELECT from_stop_id
                                              FROM route_segments
                                              WHERE route_id = ?)
                                              UNION
                                              (SELECT to_stop_id
                                              FROM route_segments
                                              WHERE route_id = ?))", self.id, self.id],
                              :include => :locality)
    end
    return stops
  end

  # where can this route end up if you get on here?
  def final_stops(current)
    conn = JourneyPattern.connection
    journeys_from_here = conn.select_values("SELECT journey_pattern_id
                                                                  FROM route_segments
                                                                  WHERE from_stop_id = #{conn.quote(current.id)}
                                                                  AND route_id = #{conn.quote(self.id)}")
    final_stops = Stop.find(:all, :conditions => ["id in (SELECT to_stop_id
                                                          FROM route_segments
                                                          WHERE to_terminus = ?
                                                          AND journey_pattern_id in (?))",
                                                   true, journeys_from_here])
    if final_stops.empty?
      final_stops = [current]
    end
    final_stops
  end

  # sometimes we need to know the terminuses of a new route, but if the route's in the database
  # then it's quicker to pull them out
  def terminuses
    if new_record?
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
      terminuses = terminuses.uniq
    else
      terminuses = _get_locations(terminuses_only=true)
    end
    return terminuses
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

  def cache_route_coords
    return if stops.empty?
    lons = self.stops.map{ |element| element.lon }
    lats = self.stops.map{ |element| element.lat }
    lon = lons.min + ((lons.max - lons.min)/2)
    lat = lats.min + ((lats.max - lats.min)/2)
    self.lat = lat
    self.lon = lon
  end

  def generate_default_journey
    self.default_journey = JourneyPattern.find(:first, :conditions => ["id =
                                                      (SELECT journey_pattern_id from
                                                        (SELECT journey_pattern_id, count(*) as cnt
                                                        FROM route_segments
                                                        WHERE route_id = ?
                                                        GROUP BY journey_pattern_id
                                                        ORDER BY cnt desc limit 1)
                                                      as tmp)", self.id])
  end

  # class methods

  def self.full_find(id, scope)
    find(id, :scope => scope, :include => { :route_operators => :operator })
  end

  # Return routes with this number and transport mode that have a stop or stop area in common with
  # the route given
  def self.find_all_by_number_and_common_stop(new_route, options={})
    stop_codes = new_route.stop_codes
    # do we think we know the operator for this route? If so, return any route with the same operator that
    # meets our other criteria. If we don't know the operator, or we pass the :use_operator_codes option
    # only return routes with the same operator code (optionally only from the same admin area)
    if ! options[:skip_operator_comparison]

      if new_route.route_operators.size == 1 && !options[:use_operator_codes]
        operator_clause = "AND route_operators.operator_id = ? "
        operator_params = [new_route.route_operators.first.operator_id]
      else
        source_admin_area = new_route.route_source_admin_areas.first
        operator_clauses = []
        operator_params = []

        new_route.route_source_admin_areas.each do |route_source_admin_area|

          next if route_source_admin_area.operator_code.blank?
          route_operator_clauses = []

          if ! options[:any_admin_area]
            if route_source_admin_area.source_admin_area_id
              route_operator_clauses << "(route_source_admin_areas.source_admin_area_id = ? AND "
              operator_params << route_source_admin_area.source_admin_area_id
            else
              route_operator_clauses << "(route_source_admin_areas.source_admin_area_id is NULL AND "
            end
          else
            route_operator_clauses << "("
          end
          route_operator_clauses << "route_source_admin_areas.operator_code = ?)"
          operator_params << route_source_admin_area.operator_code
          operator_clauses << route_operator_clauses.join(" ")
        end
        operator_clause = "AND (#{operator_clauses.join(" OR ")})"
      end
    else
      operator_clause = ''
      operator_params = []
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
        if options[:require_total_match]
          fraction_matching = (stop_codes_in_both.size.to_f / stop_codes.size.to_f)
          if fraction_matching == 1.0
            routes_with_same_stops << route
            next
          end
        else
          routes_with_same_stops << route
          next
        end

      end
      if !options[:require_total_match]
        route_stop_area_codes = route.stop_area_codes
        stop_area_codes_in_both = (stop_area_codes & route_stop_area_codes)
        if stop_area_codes_in_both.size > 0
          routes_with_same_stops << route
        end
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
    query = 'routes.id not in (SELECT route_id FROM route_operators)'
    params = []
    if options[:operator_codes]
      query += " AND route_source_admin_areas.operator_code in (?)"
      params << options[:operator_codes]
    end
    params = [query] + params
    find(:all, :conditions => params,
         :limit => options[:limit],
         :order => options[:order],
         :include => :route_source_admin_areas)
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

  def self.count_without_contacts
    count(:conditions => ['route_operators.operator_id not in
                          (select operator_id from operator_contacts where deleted = ?)', false],
          :include => :route_operators)
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
