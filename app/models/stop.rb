# == Schema Information
# Schema version: 20100707152350
#
# Table name: stops
#
#  id                       :integer         not null, primary key
#  atco_code                :string(255)
#  naptan_code              :string(255)
#  plate_code               :string(255)
#  common_name              :text
#  short_common_name        :text
#  landmark                 :text
#  street                   :text
#  crossing                 :text
#  indicator                :text
#  bearing                  :string(255)
#  town                     :string(255)
#  suburb                   :string(255)
#  locality_centre          :boolean
#  grid_type                :string(255)
#  easting                  :float
#  northing                 :float
#  lon                      :float
#  lat                      :float
#  stop_type                :string(255)
#  bus_stop_type            :string(255)
#  administrative_area_code :string(255)
#  creation_datetime        :datetime
#  modification_datetime    :datetime
#  revision_number          :integer
#  modification             :string(255)
#  status                   :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  coords                   :geometry
#  locality_id              :integer
#  cached_slug              :string(255)
#  loaded                   :boolean
#


class Stop < ActiveRecord::Base
  include FixMyTransport::Locations
  include FixMyTransport::StopsAndStopAreas
  include FixMyTransport::GeoFunctions

  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generations
  exists_in_data_generation( :identity_fields => [:atco_code],
                             :descriptor_fields => [:name],
                             :deletion_field => :modification,
                             :deletion_value => 'del',
                             :auto_update_fields => [:cached_description, :cached_slug, :metro_stop,
                                                     :coords],
                             :data_generation_associations => [:locality] )
  has_many :stop_area_memberships
  has_many :stop_areas, :through => :stop_area_memberships
  validates_presence_of :common_name
  has_many :route_segments_as_from_stop, :foreign_key => 'from_stop_id',
                                         :class_name => 'RouteSegment'
  has_many :route_segments_as_to_stop, :foreign_key => 'to_stop_id',
                                       :class_name => 'RouteSegment'
  has_many :comments, :as => :commented, :order => 'confirmed_at asc'
  belongs_to :locality
  has_many :stop_operators, :dependent => :destroy
  has_many :operators, :through => :stop_operators,
                       :uniq => true
  validates_presence_of :locality_id, :lon, :lat, :if => :loaded?
  validate :atco_code_unique_in_generation
  validate :other_code_unique_in_generation
  validates_inclusion_of :status, :in => self.statuses.keys
  # load common stop/stop area functions from stops_and_stop_areas
  is_stop_or_stop_area
  is_location
  has_friendly_id :name_with_indicator, :use_slug => true, :scope => :locality
  has_paper_trail :meta => { :replayable  => Proc.new { |instance| instance.replayable },
                             :replay_of => Proc.new { |instance| instance.replay_of },
                             :generation => CURRENT_GENERATION }
  before_save :cache_description, :update_coords
  # set attributes to include and exclude when performing model diffs
  diff :include => [:locality_id]

  # instance methods

  # this is a custom validation as atco codes need only be unique within the data generation bounds
  # set by the default scope. Allows blank values
  def atco_code_unique_in_generation
    self.field_unique_in_generation(:atco_code)
  end

  def other_code_unique_in_generation
    self.field_unique_in_generation(:other_code)
  end

  def routes
    Route.find(:all, :conditions => ['id in (SELECT route_id
                                             FROM route_segments
                                             WHERE from_stop_id = ?
                                             OR to_stop_id = ?)', self.id, self.id],
                      :include => :region )
  end

  def name
    common_name
  end

  def transport_modes
    modes = self.routes.map{ |route| route.transport_mode }.uniq
    if modes.empty?
      modes = TransportMode.find(StopType.transport_modes_for_code(stop_type))
    end
    modes
  end

  def transport_mode_ids
    transport_modes.map{ |mode| mode.id }
  end

  def transport_mode_names
    transport_modes.map{ |mode| mode.name }
  end

  def full_name
    "#{name_with_long_indicator}#{suffix}"
  end

  def suffix
    suffix = ''
    if transport_mode_names.include? 'Bus'
      suffix = " bus stop"
    end
    suffix
  end

  def name_with_indicator
    text = name
    if !indicator.blank? and ! /\d\d\d\d/.match(indicator)
      text += " #{indicator}"
    end
    text
  end

  def name_with_long_indicator
    text = name
    if !indicator.blank?
      text += " (#{long_indicator})"
    end
    text
  end

  def long_indicator
    case indicator
    when 'o/s'
      'outside'
    when 'opp'
      'opposite'
    when 'adj'
      'adjacent'
    else
      indicator
    end
  end

  def description
    return cached_description if cached_description
    "#{full_name} in #{area}"
  end

  def area
    locality_name
  end

  def name_and_bearing
    text = "#{name}"
    text += " (#{bearing})" if ! bearing.blank?
    text
  end

  def all_stop_areas
    all_stop_areas = []
    stop_areas.each do |stop_area|
      all_stop_areas << stop_area
      all_stop_areas += stop_area.ancestors
    end
    all_stop_areas
  end

  def root_stop_area(area_type)
    root_stop_areas = all_stop_areas.select{ |stop_area| stop_area.area_type == area_type }.uniq
    root_stop_areas = root_stop_areas.select{ |stop_area| stop_area.root? } if root_stop_areas.size > 1
    raise "More than one root stop area for stop #{id} #{root_stop_areas.inspect}" if root_stop_areas.size > 1
    return nil if root_stop_areas.empty?
    return root_stop_areas.first
  end

  # class methods
  # Try to find a common stop area for a set of stops
  def self.common_area(stops, transport_mode_id)
    stop_area_type_codes = StopAreaType.codes_for_transport_mode(transport_mode_id)
    stop_area_sets = stops.map do |stop|
      stop.all_stop_areas.select{ |stop_area| stop_area_type_codes.include? stop_area.area_type }
    end
    stop_areas = stop_area_sets.inject{ |intersection_set,stop_area_set| intersection_set & stop_area_set }
    root_stop_areas = stop_areas.select{ |stop_area| stop_area.root? }
    if root_stop_areas.size == 1
      return root_stop_areas.first
    end
    if stop_areas.size == 1
      return stop_areas.first
    end
    return nil
  end

  def self.name_or_id_conditions(query, transport_mode_id, show_all_metro=false)
    query_clauses = []
    query_params = []
    if ! query.blank?
      query = query.downcase
      query_clause = "(LOWER(common_name) LIKE ?
                      OR LOWER(common_name) LIKE ?
                      OR LOWER(street) LIKE ?
                      OR LOWER(street) LIKE ?
                      OR LOWER(atco_code) LIKE ?
                      OR LOWER(atco_code) LIKE ?
                      OR LOWER(other_code) LIKE ?
                      OR LOWER(other_code) LIKE ?"
      query_params = [ "#{query}%", "%#{query}%",
                       "#{query}%", "%#{query}%",
                       "#{query}%", "%#{query}%",
                       "#{query}%", "%#{query}%" ]
      # numeric?
      if query.to_i.to_s == query
        query_clause += " OR id = ?"
        query_params << query.to_i
      end
      query_clause += ")"
      query_clauses << query_clause
    end

    if !transport_mode_id.blank?
      query_clause, query_param_list = StopType.conditions_for_transport_mode(transport_mode_id.to_i, show_all_metro)
      query_clauses << query_clause
      query_params += query_param_list
    end
    conditions = [query_clauses.join(" AND ")] + query_params
  end

  def self.find_current_by_name_or_id(query, transport_mode_id, limit, show_all_metro=false)
    current.find(:all,
                 :conditions => name_or_id_conditions(query, transport_mode_id, show_all_metro),
                 :limit => limit,
                 :order => 'common_name asc')
  end

  def self.find_current_in_bounding_box(coords, options={})
    query = "stops.stop_type in (?)
             AND status = 'ACT'
             AND stops.coords && ST_Transform(ST_SetSRID(ST_MakeBox2D(
             ST_Point(?, ?),
             ST_Point(?, ?)), #{WGS_84}), #{BRITISH_NATIONAL_GRID})"
    params = [StopType.primary_types, coords[:left], coords[:bottom], coords[:right], coords[:top]]
    if options[:exclude_ids] && !options[:exclude_ids].empty?
      query += " AND id not in (?)"
      params << options[:exclude_ids]
    end
    stops = current.find(:all, :conditions => [query] + params,
                               :include => :locality)
    return stops
  end

  def self.find_current_by_atco_code(atco_code, options={})
    return nil if atco_code.blank?
    includes = options[:includes] or {}
    current.find(:first, :conditions => ["lower(atco_code) = ?", atco_code.downcase], :include => includes)
  end

  def self.find_current_by_code(code, options={})
    return nil if code.blank?
    includes = options[:includes] or {}
    atco_match = self.find_current_by_atco_code(code)
    return atco_match if atco_match
    find(:first, :conditions => ["lower(other_code) = ?", code.downcase], :include => includes)
  end

  # find the nearest stop to a set of National Grid coordinates. Accepts a model id to
  # exclude from results, and an extra condition string to constrain the search
  def self.find_nearest_current(easting, northing, exclude_id = nil, extra_conditions=nil)
    conditions = nil
    if exclude_id
      conditions = ["id != ?", exclude_id]
    end
    if extra_conditions
      if conditions
        conditions[0] = conditions[0] + " AND #{extra_conditions}"
      else
        conditions = [extra_conditions]
      end
    end
    stops = find(:first, :order => "ST_Distance(
                       ST_GeomFromText('POINT(#{easting} #{northing})', #{BRITISH_NATIONAL_GRID}),
                       stops.coords) asc",
                       :conditions => conditions)
  end

  def self.find_current(id, scope)
    find(id, :scope => scope, :include => [:locality])
  end

end
