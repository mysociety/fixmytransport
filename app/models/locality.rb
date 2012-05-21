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
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generations
  exists_in_data_generation( :identity_fields => [:code],
                             :new_record_fields => [:name,
                                                    :admin_area_id,
                                                    :district_id,
                                                    :qualifier_name,
                                                    :easting,
                                                    :northing],
                             :update_fields => [:short_name,
                                                :source_locality_type,
                                                :grid_type,
                                                :creation_datetime,
                                                :modification_datetime,
                                                :modification,
                                                :revision_number],
                             :deletion_field => :modification,
                             :deletion_value => 'del' )
  belongs_to :admin_area
  belongs_to :district
  has_dag_links :link_class_name => 'LocalityLink'
  has_many :stops, :order => 'common_name asc'
  has_many :stop_areas
  has_many :route_localities
  has_many :routes, :through => :route_localities
  has_friendly_id :name_and_qualifier_name, :use_slug => true
  before_save :set_metaphones
  # instance methods

  def name_and_qualifier_name
    "#{name} #{qualifier_name}"
  end

  def name_and_qualifier_name_with_comma
    text = name
    if !qualifier_name.blank?
      text += ", #{qualifier_name}"
    elsif !district.blank?
      text += ", #{district.name}"
    elsif !admin_area.blank?
      text += ", #{admin_area.name}"
    end
    text
  end

  def full_name
    name_and_qualifier_name_with_comma
  end

  # Set metaphones used to find localities in the case of mis-spelt searches
  def set_metaphones
    if self.new_record? || self.name_changed?
      normalized_name = self.name.gsub(' & ', ' and ')
      self.primary_metaphone, self.secondary_metaphone = Text::Metaphone.double_metaphone(normalized_name)
    end
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

  def self.find_all_by_full_name(name)
    name, qualifier_name = self.get_name_and_qualifier(name)
    results = self._find_all_by_name_and_qualifier(name, qualifier_name)
    if results.empty?
      name_with_ampersand = name.gsub(' and ', ' & ')
      if name_with_ampersand != name
        results = self._find_all_by_name_and_qualifier(name_with_ampersand, qualifier_name)
      else
        name_with_and = name.gsub(' & ', ' and ')
        if name_with_and != name
          results = self._find_all_by_name_and_qualifier(name_with_and, qualifier_name)
        end
      end
    end
    return results
  end

  def self._find_all_by_name_and_qualifier(name, qualifier_name)
    query_clause = "LOWER(localities.name) = ?"
    query_params = [ name ]
    includes = [:admin_area, :district]
    if qualifier_name
      query_clause += " AND (LOWER(qualifier_name) = ?
                         OR LOWER(districts.name) = ?
                         OR LOWER(admin_areas.name) = ?)"
      3.times{ query_params << qualifier_name }
    end

    return find(:all, :conditions => [query_clause] + query_params,
                :include => includes, :order => "localities.name asc")
  end

  def self.get_name_and_qualifier(name)
    name = name.downcase
     name_parts = name.split(',', 2)
     if name_parts.size == 2
       name = name_parts.first.strip
       qualifier_name = name_parts.second.strip
     else
       qualifier_name = nil
     end
     [name, qualifier_name]
  end

  def self.find_areas_by_name(name, area_type)
    area_types = ['Locality', 'AdminArea', 'District', 'Region']
    areas = []
    if area_type && area_types.include?(area_type)
      areas = area_type.constantize.find_all_by_full_name(name)
      return areas
    end
    area_types.each do |area_type|
      areas += area_type.constantize.find_all_by_full_name(name)
    end
    areas.each do |area|
      if area.is_a?(Locality) && (areas.include?(area.admin_area.region) || areas.include?(area.admin_area) || areas.include?(area.district))
        areas.delete(area)
      end
    end
    if areas.empty?
      areas += self.find_by_double_metaphone(name)
    end
    areas
  end

  def self.find_by_double_metaphone(name)
    name, qualifier_name = self.get_name_and_qualifier(name)
    primary_metaphone, secondary_metaphone = Text::Metaphone.double_metaphone(name)
    results = Locality.find(:all, :conditions => ['primary_metaphone = ?', primary_metaphone],
                                  :order => 'name')
  end

  def self.find_with_descendants(area)
    if area.class != Locality
      localities = area.localities
    else
      localities = [area]
    end
    descendents = find_by_sql(["SELECT localities.*
                               FROM localities INNER JOIN locality_links
                               ON localities.id = locality_links.descendant_id
                               WHERE ((locality_links.ancestor_id in (?)))", localities])
    with_descendants = localities + descendents
  end

  def self.find_by_coordinates(easting, northing, distance=1000)
    distance_clause = "ST_Distance(
                       ST_GeomFromText('POINT(#{easting} #{northing})', #{BRITISH_NATIONAL_GRID}),
                       localities.coords)"
    localities = find(:all, :conditions => ["#{distance_clause} < ?", distance],
                      :order => "#{distance_clause} asc")
  end

end
