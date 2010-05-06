# == Schema Information
# Schema version: 20100506162135
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
#

class StopArea < ActiveRecord::Base
  has_many :stop_area_memberships
  has_many :stops, :through => :stop_area_memberships
  has_dag_links :link_class_name => 'StopAreaLink'
  has_many :problems, :as => :location                                  
  
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
  
  def area
    areas = stops.map{ |stop| stop.area }.uniq
    if areas.size == 1
      return areas.first
    end
    return nil
  end
  
end
