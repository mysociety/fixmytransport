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
  validates_presence_of :transport_mode_id, :unless => :location
  validates_presence_of :description, :subject, :if => :location
  validate :validate_location_attributes
  belongs_to :reporter, :class_name => 'User'
  accepts_nested_attributes_for :reporter
  belongs_to :location, :polymorphic => true
  belongs_to :transport_mode
  attr_accessor :location_attributes, :locations, :location_search
  after_create :send_confirmation_email
  before_create :generate_confirmation_token
  named_scope :confirmed, :conditions => ['confirmed = ?', true], :order => 'created_at desc'
  cattr_reader :per_page
  @@per_page = 10
  
  def validate_location_attributes
    return true if location
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
    using_postcode = false
    if ! location_attributes[:area].blank?
      using_postcode = MySociety::Validate.is_valid_postcode(location_attributes[:area])
      location_type = 'Stop' if ! location_type
    end
    if location_type == 'Stop'
      if using_postcode
        location_search.add_method('Stop.find_by_postcode') if location_search      
        self.locations = Stop.find_by_postcode(postcode, transport_mode_id, options={:limit => MAX_LOCATION_RESULTS})
      else
        location_search.add_method('Gazetteer.find_stops_from_attributes') if location_search
        self.locations = Gazetteer.find_stops_from_attributes(location_attributes, limit=MAX_LOCATION_RESULTS)
      end
      if self.locations.size == 1  
        return
      end
      if self.locations.size > 1 
        if stop_area = Stop.common_area(self.locations, transport_mode_id)
          self.locations = [stop_area]
          location_search.add_method('Stop.common_area') if location_search
          return
        end
      end
    else
      routes = Route.find_from_attributes(location_attributes, limit=MAX_LOCATION_RESULTS)
      location_search.add_method('Route.find_from_attributes') if location_search
      self.locations = routes
      if self.locations.size == 1
        return
      end
      if self.locations.empty? 
        location_search.add_method('Gazetteer.find_routes_from_attributes') if location_search
        self.locations = Gazetteer.find_routes_from_attributes(location_attributes, limit=MAX_LOCATION_RESULTS)
      end
    end
    return
  end
  
  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end
  
  def send_confirmation_email
    ProblemMailer.deliver_story_confirmation(reporter, self, token)
  end
  
end
