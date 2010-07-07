# == Schema Information
# Schema version: 20100506162135
#
# Table name: localities
#
#  id                    :integer         not null, primary key
#  code                  :string(255)
#  atco_code             :string(255)
#  name                  :text
#  short_name            :text
#  country               :string(255)
#  region_code           :string(255)
#  national              :boolean
#  contact_email         :string(255)
#  contact_telephone     :string(255)
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :string(255)
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
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
