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
  extend ActiveSupport::Memoizable
  
  named_scope :active, :conditions => { :status => 'act' }
  has_many :stop_area_memberships
  has_many :stop_areas, :through => :stop_area_memberships
  validates_presence_of :common_name
  has_many :campaigns, :as => :location, :order => 'created_at desc'
  has_many :problems, :as => :location, :order => 'created_at desc'
  has_many :route_segments_as_from_stop, :foreign_key => 'from_stop_id', :class_name => 'RouteSegment'
  has_many :route_segments_as_to_stop, :foreign_key => 'to_stop_id', :class_name => 'RouteSegment'
  has_many :routes_as_from_stop, :through => :route_segments_as_from_stop, :source => 'route'
  has_many :routes_as_to_stop, :through => :route_segments_as_to_stop, :source => 'route'
  has_many :stop_operators, :dependent => :destroy
  has_many :operators, :through => :stop_operators, :uniq => true
  belongs_to :locality
  validates_presence_of :locality_id, :lon, :lat, :if => :loaded?
  # load common stop/stop area functions from stops_and_stop_areas
  is_stop_or_stop_area
  has_friendly_id :name_with_indicator, :use_slug => true, :scope => :locality, :cache_column => false
  has_paper_trail
  
  # instance methods
  
  def routes
    (routes_as_from_stop | routes_as_to_stop).uniq.sort{ |a,b| a.name <=> b.name }
  end
  
  def name
    common_name
  end
  
  def transport_modes
    TransportMode.find(StopType.transport_modes_for_code(stop_type))
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
    if transport_modes.include? 'Bus'
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
    "#{full_name} in #{area}"
  end
  memoize :description
  
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
    raise "More than one root stop area for stop #{id}" if root_stop_areas.size > 1
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
  
  def self.name_or_id_conditions(query, transport_mode_id)
    query_clauses = []
    query_params = []
    if ! query.blank? 
      query = query.downcase
      query_clause = "(LOWER(common_name) LIKE ? OR LOWER(common_name) LIKE ? OR LOWER(street) LIKE ? OR LOWER(street) LIKE ?"
      query_params = [ "#{query}%", "%#{query}%", "#{query}%", "%#{query}%" ]
      # numeric?
      if query.to_i.to_s == query
        query_clause += " OR id = ?"
        query_params << query.to_i
      end
      query_clause += ")"
      query_clauses << query_clause
    end

    if !transport_mode_id.blank?
      query_clause, query_param_list = StopType.conditions_for_transport_mode(transport_mode_id.to_i)
      query_clauses << query_clause
      query_params += query_param_list
    end
    conditions = [query_clauses.join(" AND ")] + query_params
  end
  
  def self.find_by_name_or_id(query, transport_mode_id, limit)
    find(:all, 
         :conditions => name_or_id_conditions(query, transport_mode_id),
         :limit => limit)
  end
    
  def self.find_by_name_and_coords(name, easting, northing, distance)
    stops = find_by_sql(["SELECT   *, ABS(easting - ?) as easting_dist, ABS(northing - ?) as northing_dist
                          FROM     stops
                          WHERE    common_name = ? 
                          AND      ABS(easting - ?) < ? 
                          AND      ABS(northing - ?) < ?
                          ORDER BY easting_dist asc, northing_dist asc
                          LIMIT 1",
                          easting, northing, name, easting, distance, northing, distance])
    stops.empty? ? nil : stops.first
  end
  
  def self.find_in_bounding_box
    stops = find_by_sql(["SELECT *
                          FROM stops
                          WHERE stops.coords && ST_SetSRID(ST_MakeBox2D(
                            ST_Point(?, ?),
    	                      ST_Point(?, ?)), #{BRITISH_NATIONAL_GRID})",
    	                      358941, 173524, 358935, 173519])
  # -12039.543072383,6709347.2102621
  # -11537.925074351,6709824.9416887
  end
  
  def self.find_by_atco_code(atco_code, options={})
    includes = options[:includes] or {}
    find(:first, :conditions => ["lower(atco_code) = ?", atco_code.downcase], :include => includes)
  end
  
  def self.match_old_stop(stop)
     existing = find_by_atco_code(stop.atco_code)
     return existing if existing
     existing = find_by_name_and_coords(stop.common_name, stop.easting, stop.northing, 5)     
     return existing if existing
     existing = find_by_easting_and_northing(stop.easting, stop.northing)
     return existing if existing
     return nil
  end
  
  def self.full_find(id, scope)
    find(id, :scope => scope, 
         :include => [ { :routes_as_from_stop => [:region, :route_segments] }, 
                       { :routes_as_to_stop => [:region, :route_segments] }, 
                       :locality,
                       { :stop_areas => :locality } ])
  end
  
end
