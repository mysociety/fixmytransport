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
  include FixMyTransport::Locations

  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generations
  exists_in_data_generation( :identity_fields => [],
                             :descriptor_fields => [:number, {:region => [:persistent_id]}],
                             :replay_merges => false,
                             :auto_update_fields => [:cached_description,
                                                     :cached_slug,
                                                     :lat,
                                                     :lon,
                                                     :cached_area,
                                                     :cached_short_name,
                                                     :coords] )
  has_many :route_sub_routes
  has_many :sub_routes, :through => :route_sub_routes
  has_many :route_operators, :dependent => :destroy,
                             :uniq => true
  has_many :operators, :through => :route_operators,
                       :uniq => true
  has_many :journey_patterns, :dependent => :destroy,
                              :order => 'id asc'
  has_many :route_segments, :dependent => :destroy,
                            :order => 'id asc'

  has_many :from_stops, :through => :route_segments, :class_name => 'Stop'
  has_many :to_stops, :through => :route_segments, :class_name => 'Stop'
  belongs_to :transport_mode
  has_many :route_localities, :dependent => :destroy
  has_many :localities, :through => :route_localities
  has_many :comments, :as => :commented, :order => 'confirmed_at asc'
  belongs_to :region
  belongs_to :default_journey, :class_name => 'JourneyPattern'

  # Routes loaded from TNDS have route_source records
  has_many :route_sources, :dependent => :destroy
  # Routes loaded from NPTDR have route_source_admin_area records
  has_many :route_source_admin_areas, :dependent => :destroy
  has_many :source_admin_areas, :through => :route_source_admin_areas,
                                :class_name => 'AdminArea'
  accepts_nested_attributes_for :route_operators, :allow_destroy => true, :reject_if => :route_operator_invalid
  accepts_nested_attributes_for :journey_patterns, :allow_destroy => true, :reject_if => :journey_pattern_invalid
  validates_presence_of :number, :transport_mode_id
  validates_presence_of :region_id, :if => :loaded?
  validates_inclusion_of :status, :in => self.statuses.keys
  cattr_reader :per_page
  has_friendly_id :short_name, :use_slug => true, :scope => :region
  has_paper_trail :meta => { :replayable  => Proc.new { |instance| instance.replayable },
                             :replay_of => Proc.new { |instance| instance.replay_of } }
  paper_trail_restorable_associations [ :route_operators => { :foreign_key => :route_id,
                                                              :attributes => [:operator] } ]
  attr_accessor :show_as_point, :operator_info, :missing_stops
  before_save [ :cache_route_coords,
                :cache_area,
                :cache_description,
                :cache_short_name,
                :update_route_localities ]
  after_save :generate_default_journey
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
  memoize :stop_codes

  def stop_area_codes
    stop_areas = stops.map{ |stop| stop.stop_areas }.flatten
    stop_areas.map{ |stop_area| stop_area.code }.uniq
  end
  memoize :stop_area_codes

  def transport_mode_name
    transport_mode.name if transport_mode
    nil
  end

  def cache_area
    self.cached_area = nil
    self.cached_area = self.area
  end

  def cache_short_name
    self.cached_short_name = nil
    self.cached_short_name = self.short_name
  end

  def update_route_localities
    locality_ids = []
    stops.each do |stop|
      locality_ids << stop.locality_id unless locality_ids.include? stop.locality_id
    end
    locality_ids.each do |locality_id|
      if ! self.route_localities.detect{ |existing| existing.locality_id == locality_id }
        self.route_localities.build(:locality_id => locality_id)
      end
    end
    self.route_localities.each do |route_locality|
      if !locality_ids.include?(route_locality.locality_id)
        route_locality.destroy
      end
    end
    # update the region based on the localities
    regions = self.route_localities.map{ |route_locality| route_locality.locality.admin_area.region }.uniq

    if regions.size > 1
      regions = [ Region.current.find_by_name('Great Britain') ]
    end
    if regions.empty?
      self.region = nil
    else
      self.region = regions.first
    end
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
    if !area.blank?
      if lowercase == true
        area[0] = area.first.downcase
      else
        area[0] = area.first.upcase
      end
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

  def short_name
    return self.cached_short_name if self.cached_short_name
    name(from_stop=nil, short=true)
  end

  def short_name_with_inactive
    text = "#{short_name}"
    if self.status == 'DEL'
      text += " (#{I18n.translate('models.route.inactive')})"
    end
    text
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
    if self.status == 'DEL'
      text += " (#{I18n.translate('models.route.inactive')})"
    end
    text
  end

  def description_with_inactive
    text = "#{description}"
    if self.status == 'DEL'
      text += " (#{I18n.translate('models.route.inactive')})"
    end
    text
  end

  def operator_text
    operators.map{ |operator| operator.name }.to_sentence
  end

  def responsible_organizations
    if self.london_bus_route?
      return [PassengerTransportExecutive.find_by_name('Transport for London')]
    end
    operators
  end

  def councils_responsible?
    false
  end

  def passenger_transport_executive
    if self.london_bus_route?
      return PassengerTransportExecutive.find_by_name('Transport for London')
    else
      return nil
    end
  end

  def pte_responsible?
    if self.london_bus_route?
      return true
    end
    return false
  end

  def operators_responsible?
    if self.london_bus_route?
      return false
    end
    return true
  end

  def london_bus_route?
    return false if self.number == 'ZZ9'
    return (self.transport_mode_name == 'Bus' && self.region.name == 'London')
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
    self.send(:update_without_callbacks)
  end

  def find_previous_route_operators(verbose, dryrun)
    self.route_operators.each do |route_operator|
      previous_route_operator = RouteOperator.find_in_generation_by_identity_hash(route_operator,
                                                                                  PREVIOUS_GENERATION)

      if previous_route_operator
        route_operator.previous_id = previous_route_operator.id
        route_operator.persistent_id = previous_route_operator.persistent_id
        if !route_operator.valid?
          puts "ERROR: Route operator is invalid:"
          puts route_operator.inspect
          puts route_operator.errors.full_messages.join("\n")
          return
        end

        if ! dryrun
          puts "Saving route operator" if verbose
          route_operator.save!
        end
      end
    end
  end

  # class methods

  # Find a match for a route in a given generation
  def self.find_in_generation_by_attributes(route, generation, verbose, options={})
    operators = route.route_operators.map{ |route_operator| route_operator.operator.name }.join(", ")
    puts "Route id: #{route.id}, number: #{route.number}, operators: #{operators}" if verbose
    previous = route.class.find_existing(route, { :generation => generation })
    puts "Found #{previous.size} routes" if verbose
    multiple = options.has_key?(:multiple) ? options[:multiple] : false
    if previous.size == 0
      previous = route.class.find_existing(route, { :skip_operator_comparison => true,
                                                    :require_match_fraction => 0.8,
                                                    :generation => generation })
      puts "Found #{previous.size} routes, on complete stop match without operators" if verbose
    end

    if previous.size > 1 && ! multiple
      # discard any of the routes that have other operators
      previous = previous.delete_if do |previous_route|
        other_operators = previous_route.operators.any?{ |operator| ! route.operators.include?(operator) }
        if other_operators
          puts "Rejecting #{previous_route.id} as it has other operators" if verbose
        end
        other_operators
      end
    end
    if previous.size > 1 && ! multiple
      route_ids = previous.map{ |previous_route| previous_route.id }.join(", ")
      puts "Matched more than one previous route! #{route_ids}" if verbose
      return nil
    end
    if previous.size == 0
      puts "No routes matched" if verbose
      if multiple
        return []
      else
        return nil
      end
    end
    if multiple
      return previous
    else
      return previous.first
    end
  end

  def self.find_current(id, scope)
    self.current.find(id, :scope => scope, :include => [{ :route_operators => :operator }])
  end

  def self.find_all_current_by_service_code_operator_code_and_region(service_code, operator_code, region)
    current.find(:all, :conditions => ['route_sources.service_code = ?
                                        AND route_sources.operator_code = ?
                                        AND route_sources.region_id = ?',
                                        service_code,
                                        operator_code,
                                        region],
                        :include => :route_sources)
  end

  # Return routes with the same number and transport mode that have a stop or stop area in common with
  # the route given. Scoped to a particular generation, the current generation by default.
  def self.find_all_by_number_and_common_stop(new_route, options={})
    stop_codes = new_route.stop_codes
    stop_area_codes = new_route.stop_area_codes
    generation = options[:generation] || CURRENT_GENERATION
    # do we think we know the operator for this route? If so, return any route with the same operator that
    # meets our other criteria. If we don't know the operator, or we pass the :use_source_admin_areas option
    # only return routes with the same source_admin_area operator code (optionally only from the same admin area)
    # N.B. only routes loaded from NPTDR will have source_admin_areas
    operator_clause = ''
    operator_params = []
    if ! options[:skip_operator_comparison]
      if  !options[:use_source_admin_areas]
        if new_route.route_operators.length >= 1
          operator_ids = new_route.route_operators.map do |route_operator|
            operator = Operator.find_in_generation_by_id(route_operator.operator_id, generation)
            operator ? operator.id : nil
          end
          operator_ids.compact!
          if operator_ids.size > 0
            operator_clause = "AND route_operators.operator_id in (?)"
            operator_params = [ operator_ids ]
          else
            # None of the operators exist in this generation, so return an empty set of routes
            return []
          end
        end
      elsif new_route.route_source_admin_areas.length >= 1
        operator_clauses = []
        operator_params = []

        new_route.route_source_admin_areas.each do |route_source_admin_area|

          next if route_source_admin_area.operator_code.blank?
          route_operator_clauses = []

          if ! options[:any_admin_area]
            admin_area_id = route_source_admin_area.source_admin_area_id
            if admin_area_id
              route_operator_clauses << "(route_source_admin_areas.source_admin_area_id = ? AND "
              operator_params << AdminArea.find_in_generation_by_id(admin_area_id, generation)
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
    end

    id_clause = ''
    id_params = []
    if new_route.id
      id_clause = " AND routes.id != ?"
      id_params = [new_route.id]
    end

    condition_string = "(routes.number = ? OR routes.name = ?)
                        AND routes.transport_mode_id = ? #{operator_clause} #{id_clause}"
    conditions = [condition_string, new_route.number, new_route.number, new_route.transport_mode.id]
    conditions += operator_params
    conditions += id_params
    routes = Route.in_generation(generation).find(:all, :conditions => conditions,
                                :include => [ {:journey_patterns => {:route_segments => [:from_stop, :to_stop] }},
                                               :route_operators,
                                               :route_source_admin_areas ])
    routes_with_same_stops = []

    routes.each do |route|
      route_stop_codes = route.stop_codes
      stop_codes_in_both = (stop_codes & route_stop_codes)

      if stop_codes_in_both.size > 0
        if options[:require_match_fraction]
          fraction_matching = (stop_codes_in_both.size.to_f / stop_codes.size.to_f)
          puts "Match between #{route.id} and #{new_route.id} - required match #{options[:require_match_fraction]}, fraction_matching = #{fraction_matching}"
          if fraction_matching >= options[:require_match_fraction]
            routes_with_same_stops << route
            next
          end
        else
          routes_with_same_stops << route
          next
        end
      end
      # If we haven't required a match fraction, include anything that goes through any of the same
      # stop areas
      if !options[:require_match_fraction]
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

  # Accepts two arrays of locations (stops or stop areas). Finds routes that pass through at least one
  # location ineach array. Additional params to constrain the search can be passed as options. Scoped
  # by generation, by default the current generation
  def self.find_all_by_locations(from_locations, to_locations, options)
    generation = options[:generation] || CURRENT_GENERATION
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
      params << Operator.find_in_generation_by_id(options[:operator_id], generation)
      include_params << :route_operators
    end

    if options[:source_admin_area]
      admin_area = AdminArea.find_in_generation(options[:source_admin_area].source_admin_area, generation)
      condition_string += " AND route_source_admin_areas.operator_code = ?
                            AND route_source_admin_areas.source_admin_area_id = ?"
      params << options[:source_admin_area].operator_code
      params << admin_area.id
      include_params << :route_source_admin_areas
    end

    include_params << :route_segments
    joins = ''
    last_index = nil

    [from_locations, to_locations].each_with_index do |locations,index|
      if options[:as_terminus]
        from_terminus_clause = "rs#{index}.from_terminus = 't' and"
        to_terminus_clause = "rs#{index}.to_terminus = 't' and"
      end
      if locations.all?{ |location| location.is_a?(StopArea) }
        location_key = 'stop_area_id'
      else
        location_key = 'stop_id'
      end
      joins += " inner join route_segments rs#{index} on routes.id = rs#{index}.route_id"
      condition_string += " and ((#{from_terminus_clause} rs#{index}.from_#{location_key} in (?))"
      condition_string += " or (#{to_terminus_clause} rs#{index}.to_#{location_key} in (?)))"
      locations_in_generation = locations.map do |location|
        location.class.find_in_generation(location, generation)
      end
      params << locations_in_generation
      params << locations_in_generation
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
    Route.in_generation(generation).find(routes.map{ |route| route.id })
  end

  def self.find_existing_routes(new_route, options={})
    find_all_by_number_and_common_stop(new_route, options)
  end


  def self.find_current_without_operators(options={})
    if !options.has_key?(:order)
      options[:order] = 'number ASC'
    end
    query = 'routes.id not in (SELECT route_id FROM route_operators)'
    params = []
    if options[:operator_codes]
      route_sources = RouteSource.current.find(:all,
                                               :select => 'distinct route_id',
                                               :conditions => ["operator_code in (?)", options[:operator_codes]])
      route_ids = route_sources.map{ |route_source| route_source.route_id }
      route_source_admin_areas = RouteSourceAdminArea.current.find(:all,
                                                                   :select => 'distinct route_id',
                                                                   :conditions => ['operator_code in (?)',
                                                                           options[:operator_codes]])
      route_ids += route_source_admin_areas.map{ |route_source| route_source.route_id }
      query += " AND id in (?)"
      params << route_ids
    end
    params = [query] + params
    current.find(:all, :conditions => params,
                       :limit => options[:limit],
                       :order => options[:order],
                       :include => :region)
  end

  def self.count_current_without_operators(options={})
    current.count(:conditions => ['id not in (SELECT route_id FROM route_operators)'])
  end

  # finds operator codes that are associated with routes
  # where the route doesn't have an operator
  def self.find_current_codes_without_operators(options={})
    query = "SELECT operator_code, sum(cnt) as total_count FROM
               ((SELECT operator_code, count(distinct route_id) as cnt
                FROM route_sources
                WHERE route_id not in
                  (SELECT route_id
                   FROM route_operators)
                AND operator_code is not null
                AND generation_low <= #{CURRENT_GENERATION}
                AND generation_high >= #{CURRENT_GENERATION}
                GROUP BY operator_code)
                UNION ALL
                (SELECT operator_code, count(distinct route_id) as cnt
                  FROM route_source_admin_areas
                  WHERE route_id not in
                    (SELECT route_id
                     FROM route_operators)
                  AND operator_code is not null
                  AND generation_low <= #{CURRENT_GENERATION}
                  AND generation_high >= #{CURRENT_GENERATION}
                  GROUP BY operator_code))
                 as tmp GROUP BY operator_code
             ORDER BY total_count desc"
    if options[:limit]
      query += " LIMIT #{options[:limit]}"
    end
    connection.select_rows(query)
  end

  def self.count_current_codes_without_operators()
    find_current_codes_without_operators.size
  end

  def self.count_current_without_contacts
    current.count(:conditions => ['route_operators.operator_id not in
                                  (SELECT distinct operators.id
                                   FROM operators, operator_contacts
                                   WHERE operators.persistent_id = operator_contacts.operator_persistent_id
                                   AND operator_contacts.deleted = ?)', false],
                  :include => :route_operators)
  end

  # Return train routes by the same operator that have the same terminuses
  def Route.find_existing_train_routes(new_route, options)
    operator_code = new_route.operator_code
    options.update({ :as_terminus => true,
                     :transport_modes => [new_route.transport_mode_id] })
    if new_route.route_operators.size == 1
      options[:operator_id] = new_route.route_operators.first.operator_id
    else
      source_admin_area = new_route.route_source_admin_areas.first
      options[:source_admin_area] = source_admin_area
    end
    found_routes = []
    new_route.journey_patterns.each do |journey_pattern|
      from_terminus_segments = journey_pattern.route_segments.select{ |route_segment| route_segment.from_terminus? }
      to_terminus_segments = journey_pattern.route_segments.select{ |route_segment| route_segment.to_terminus? }
      from_terminuses = from_terminus_segments.map{ |route_segment| route_segment.from_stop_area }
      to_terminuses = to_terminus_segments.map{ |route_segment| route_segment.to_stop_area }
      found_routes << Route.find_all_by_locations(from_terminuses, to_terminuses, options)
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
    existing_routes = find_existing(route, { :generation => CURRENT_GENERATION })
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
      if find_existing(duplicate, { :generation => CURRENT_GENERATION }).include? original
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
    raise "Can't merge route with comments: #{duplicate.inspect}" if !duplicate.comments.empty?
    raise "Can't merge routes with different statuses: #{duplicate.status} vs #{original.status}" if duplicate.status != original.status
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
    duplicate.route_sources.each do |route_source|
      original.route_sources.build(:service_code => route_source.service_code,
                                   :operator_code => route_source.operator_code,
                                   :region => route_source.region,
                                   :line_number => route_source.line_number,
                                   :filename => route_source.filename)
    end

    duplicate.route_sub_routes.each do |route_sub_route|
      if ! original.route_sub_routes.detect{ |existing| existing.sub_route == route_sub_route.sub_route }
        original.route_sub_routes.build(:sub_route => route_sub_route.sub_route)
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
    if ! duplicate.new_record?
      MergeLog.create!(:from_id => duplicate.id,
                       :to_id => original.id,
                       :model_name => 'Route')
      duplicate.route_operators.each do |route_operator|
        duplicate_route_operator = original.route_operators.detect { |existing| existing.operator == route_operator.operator }
        MergeLog.create!(:from_id => route_operator.id,
                         :to_id => duplicate_route_operator.id,
                         :model_name => 'RouteOperator')
      end
      duplicate.destroy
    end
    original.save!
  end


end
