# == Schema Information
# Schema version: 20100707152350
#
# Table name: stop_areas
#
#  id                       :integer         not null, primary key
#  code                     :string(255)
#  name                     :text
#  administrative_area_code :string(255)
#  area_type                :string(255)
#  grid_type                :string(255)
#  easting                  :float
#  northing                 :float
#  creation_datetime        :datetime
#  modification_datetime    :datetime
#  revision_number          :integer
#  modification             :string(255)
#  status                   :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  coords                   :geometry
#  lon                      :float
#  lat                      :float
#  locality_id              :integer
#  loaded                   :boolean
#

class StopArea < ActiveRecord::Base
  extend ActiveSupport::Memoizable

  has_many :stop_area_memberships
  has_many :stops, :through => :stop_area_memberships
  has_dag_links :link_class_name => 'StopAreaLink'
  has_many :campaigns, :as => :location, :order => 'created_at desc'
  has_many :problems, :as => :location, :order => 'created_at desc'
  belongs_to :locality
  has_many :stop_area_operators, :dependent => :destroy
  has_many :operators, :through => :stop_area_operators, :uniq => true
  has_friendly_id :name, :use_slug => true, :scope => :locality
  has_many :route_segments_as_from_stop_area, :foreign_key => 'from_stop_area_id', :class_name => 'RouteSegment'
  has_many :route_segments_as_to_stop_area, :foreign_key => 'to_stop_area_id', :class_name => 'RouteSegment'
  has_many :routes_as_from_stop_area, :through => :route_segments_as_from_stop_area, :source => 'route'
  has_many :routes_as_to_stop_area, :through => :route_segments_as_to_stop_area, :source => 'route'
  has_many :comments, :as => :commented, :order => 'confirmed_at asc'
  accepts_nested_attributes_for :stop_area_operators, :allow_destroy => true, :reject_if => :stop_area_operator_invalid
  validates_inclusion_of :status, :in => self.statuses

  has_paper_trail
  before_save :cache_description
  # load common stop/stop area functions from stops_and_stop_areas
  is_stop_or_stop_area
  is_location
  
  def stop_area_operator_invalid(attributes)
    (attributes['_add'] != "1" and attributes['_destroy'] != "1") or attributes['operator_id'].blank?
  end

  def routes
    Route.find(:all, :conditions => ['id in (SELECT route_id
                                             FROM route_segments
                                             WHERE from_stop_area_id = ?
                                             OR to_stop_area_id = ?)', self.id, self.id],
                     :include => :region)
  end

  def route_terminuses
    routes.map{ |route| route.terminuses }.flatten.uniq.sort_by(&:name)
  end

  def description
    return cached_description if cached_description
    text = name
    text += " in #{area}" if area
    text
  end

  def full_name
    if StopAreaType.atomic_types.include?(area_type)
      name
    else
      "#{name} stop area"
    end
  end

  def transport_modes
    TransportMode.find(StopAreaType.transport_modes_for_code(area_type))
  end

  def transport_mode_ids
    transport_modes.map{ |mode| mode.id }
  end

  def transport_mode_names
    transport_modes.map{ |mode| mode.name }
  end

  def area
    areas = stops.map{ |stop| stop.area }.uniq
    if areas.size == 1
      return areas.first
    end
    return nil
  end
  memoize :area

  def self.find_in_bounding_box(coords, options={})
    query = "stop_areas.area_type in (?)
             AND status = 'ACT'
             AND stop_areas.coords && ST_Transform(ST_SetSRID(ST_MakeBox2D(
             ST_Point(?, ?),
             ST_Point(?, ?)), #{WGS_84}), #{BRITISH_NATIONAL_GRID})"
    params = [StopAreaType.primary_types, coords[:left], coords[:bottom], coords[:right], coords[:top]]
    if options[:exclude_ids] && ! options[:exclude_ids].empty?
      query += " AND id not in (?)"
      params << options[:exclude_ids]
    end
    stop_areas = find(:all, :conditions => [query] + params,
     	                      :include => :locality)
    stop_areas
  end

  def self.find_parents(stop, station_type)
    distance_clause = "ST_Distance(
                       ST_GeomFromText('POINT(#{stop.easting} #{stop.northing})', #{BRITISH_NATIONAL_GRID}),
                       coords)"
    existing_stations = StopArea.find(:all, :conditions => ["name = ?
                                                             AND area_type = ?
                                                             AND #{distance_clause} < ?",
                                                            stop.common_name, station_type, 500] )
    existing_stations = map_to_common_areas(existing_stations)
  end

  # Take a list of stop areas and remove those that are descendents of areas already in the list
  def self.map_to_common_areas(stop_areas)
    area_list = []
    stop_areas.each do |stop_area|
      unless stop_area.ancestors.any?{ |ancestor| stop_areas.include?(ancestor) }
        area_list << stop_area
      end
    end
    area_list
  end

  def self.name_or_id_conditions(query, transport_mode_id)
    query_clauses = []
    query_params = []
    if ! query.blank?
      query = query.downcase
      query_clause = "(LOWER(name) LIKE ? 
                      OR LOWER(name) LIKE ?
                      OR LOWER(code) LIKE ?
                      OR LOWER(code) LIKE ?"
      query_params = [ "#{query}%", "%#{query}%",
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
      query_clause, query_param_list = StopAreaType.conditions_for_transport_mode(transport_mode_id.to_i)
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

  def self.full_find(id, scope)
    find(id, :scope => scope, :include => :locality)
  end

  def self.find_by_code(code)
    find(:first, :conditions => ["lower(code) = ?", code.downcase])
  end

end
