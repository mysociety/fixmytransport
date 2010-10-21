# == Schema Information
# Schema version: 20100707152350
#
# Table name: localities
#
#  id                    :integer         not null, primary key
#  code                  :string(255)
#  name                  :text
#  short_name            :text
#  national              :boolean
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :string(255)
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  admin_area_id         :integer
#  qualifier_name        :string(255)
#  source_locality_type  :string(255)
#  grid_type             :string(255)
#  northing              :float
#  easting               :float
#  coords                :geometry
#  district_id           :integer
#  cached_slug           :string(255)
#

class Locality < ActiveRecord::Base
  belongs_to :admin_area
  belongs_to :district
  has_dag_links :link_class_name => 'LocalityLink'
  has_many :stops, :order => 'common_name asc'
  has_many :route_localities
  has_many :routes, :through => :route_localities
  has_friendly_id :name_and_qualifier_name, :use_slug => true
  
  # instance methods
  
  def name_and_qualifier_name
    "#{name} #{qualifier_name}"
  end
  
  # class methods
  
  def self.find_by_name_or_id(query, limit=nil)
    query_clauses = []
    query_clause = "(LOWER(name) LIKE ? 
                    OR LOWER(name) LIKE ?"
    query_params = [ "#{query}%", "%#{query}%" ]
    # numeric?
    if query.to_i.to_s == query
      query_clause += " OR id = ?"
      query_params << query.to_i
    end
    query_clause += ")"
    query_clauses << query_clause
    conditions = [query_clauses.join(" AND ")] + query_params
    find(:all, 
         :conditions => conditions, 
         :limit => limit)
  end
  
  def self.find_all_by_lower_name(name)
    name = name.downcase
    name_parts = name.split(',', 2)
    if name_parts.size == 2
      name = name_parts.first.strip
      qualifier_name = name_parts.second.strip
    else
      qualifier_name = nil
    end
    query_clause = "LOWER(name) = ?"
    query_params = [ name ]
    if qualifier_name
      query_clause += " AND LOWER(qualifier_name) = ?"
      query_params << qualifier_name
    end
    find(:all, :conditions => [query_clause] + query_params)
  end
  
  def self.find_all_by_name(name)
    localities = find_by_sql(['SELECT localities.* 
                               FROM localities 
                               LEFT OUTER JOIN admin_areas 
                               ON admin_areas.id = localities.admin_area_id 
                               LEFT OUTER JOIN regions
                               ON regions.id = admin_areas.region_id 
                               LEFT OUTER JOIN districts 
                               ON districts.id = localities.district_id 
                               WHERE (lower(localities.name) = ? 
                               OR lower(admin_areas.name) = ? 
                               OR lower(districts.name) = ?
                               OR lower(regions.name) = ?)', 
                               name.downcase, name.downcase, name.downcase, name.downcase])
    localities
  end

  def self.find_all_with_descendants(name)
    localities = find_all_by_name(name)
    descendents = find_by_sql(["SELECT localities.* 
                               FROM localities INNER JOIN locality_links
                               ON localities.id = locality_links.descendant_id 
                               WHERE ((locality_links.ancestor_id in (?)))", localities])
    with_descendants = localities + descendents
  end
  
  def self.find_by_coordinates(easting, northing)
    distance_clause = "ST_Distance(
                       ST_GeomFromText('POINT(#{easting} #{northing})', #{BRITISH_NATIONAL_GRID}), 
                       localities.coords)"
    localities = find(:all, :conditions => ["#{distance_clause} < 1000"], 
                      :order => "#{distance_clause} asc", :limit => 1)
  end
  
end
