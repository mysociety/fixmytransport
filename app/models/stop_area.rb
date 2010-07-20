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
  has_many :stories, :as => :location, :order => 'created_at desc'
  accepts_nested_attributes_for :stories
  belongs_to :locality
  has_friendly_id :name, :use_slug => true, :scope => :locality                                  
  validates_presence_of :locality, :if => :loaded?
  
  def self.full_find(id, scope)
    find(id, :scope => scope, 
         :include => { :stops => [ {:routes_as_from_stop => :region}, {:routes_as_to_stop, :region}, :locality ] } )
  end
  
  def self.find_by_code(code)
    find(:first, :conditions => ["lower(code) = ?", code.downcase])
  end
  
  def routes
    stops.map{ |stop| stop.routes }.flatten.uniq
  end
  
  def description
    text = name
    text += " in #{area}" if area
    text  
  end
  
  def transport_modes
    TransportMode.find(StopAreaType.transport_modes_for_code(area_type))
  end
  
  def transport_mode_ids
    transport_modes.map{ |mode| mode.id }
  end
  
  def area
    areas = stops.map{ |stop| stop.area }.uniq
    if areas.size == 1
      return areas.first
    end
    return nil
  end
  memoize :area
  
end
