# == Schema Information
# Schema version: 20100506162135
#
# Table name: problems
#
#  id                :integer         not null, primary key
#  subject           :text
#  description       :text
#  created_at        :datetime
#  updated_at        :datetime
#  reporter_id       :integer
#  stop_area_id      :integer
#  location_id       :integer
#  location_type     :string(255)
#  transport_mode_id :integer
#

class Problem < ActiveRecord::Base
  validates_presence_of :transport_mode_id
  validate :validate_location_attributes
  has_one :reporter, :class_name => 'User'
  accepts_nested_attributes_for :reporter
  belongs_to :location, :polymorphic => true
  belongs_to :transport_mode
  attr_accessor :location_attributes, :locations, :location_search
  
  def validate_location_attributes
    if ! location_attributes_valid?
      errors.add(:location_attributes, ActiveRecord::Error.new(self, :location_attributes, :blank).to_s)
    end
    if !location_attributes[:route_number].blank?
      self.location_type = 'Route'
    end
    if !location_attributes[:name].blank?
      self.location_type = 'Stop'
    end
  end
  
  def location_attributes_valid?
    if ! location_attributes or (location_attributes[:name].blank? and
                       location_attributes[:area].blank? and
                       location_attributes[:route_number].blank?)
      return false
    else
      return true
    end
  end
  
  def location_from_attributes
    self.locations = []
    return unless transport_mode_id
    return unless location_attributes_valid?
    location_attributes[:transport_mode_id] = transport_mode_id
    if location_type == 'Stop'
      stops = Stop.find_from_attributes(location_attributes)
      location_search.add_method('Stop.find_from_attributes') if location_search
      if stops.size == 1  
        self.locations = stops
        return
      end
      if stops.size > 1 and stops.size < 80
        if stop_area = Stop.common_area(stops, transport_mode_id)
          self.locations = [stop_area]
          location_search.add_method('Stop.common_area') if location_search
          return
        end
      end
      self.locations = stops
      if self.locations.empty? 
        location_search.add_method('Gazetteer.find_stops_from_attributes') if location_search
        self.locations = Gazetteer.find_stops_from_attributes(location_attributes)
      end
    else
      routes = Route.find_from_attributes(location_attributes)
      location_search.add_method('Route.find_from_attributes') if location_search
      self.locations = routes
      if self.locations.size == 1
        return
      end
      if self.locations.empty? 
        location_search.add_method('Gazetteer.find_routes_from_attributes') if location_search
        self.locations = Gazetteer.find_routes_from_attributes(location_attributes)
      end
    end
    return
  end
 
end
