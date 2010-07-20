# == Schema Information
# Schema version: 20100707152350
#
# Table name: transport_modes
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  naptan_name :string(255)
#  active      :boolean
#  route_type  :string(255)
#

class TransportMode < ActiveRecord::Base
  has_many :transport_mode_stop_types
  has_many :stop_types, :through => :transport_mode_stop_types
  has_many :transport_mode_stop_area_types
  has_many :stop_area_types, :through => :transport_mode_stop_area_types
  named_scope :active, :conditions => { :active => true }

  def css_name
    if self.name.blank?
      return ""
    else
      return self.name.gsub(/\W/,"").downcase
    end
  end
  
end
  
