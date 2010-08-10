class Problem < ActiveRecord::Base
  belongs_to :location, :polymorphic => true
  belongs_to :reporter, :class_name => 'User'
  belongs_to :transport_mode
  accepts_nested_attributes_for :reporter
  validates_presence_of :transport_mode_id, :unless => :location
  validates_presence_of :description, :subject, :category, :if => :location
  validate :validate_location_attributes
  attr_accessor :location_attributes, :locations, :location_search, :location_errors
  cattr_accessor :categories
  after_create :send_confirmation_email
  before_create :generate_confirmation_token
  named_scope :confirmed, :conditions => ['confirmed = ?', true], :order => 'created_at desc'
  
  @@categories = ['New route', 'Keep route', 'Get repair', 'Lateness', 'Other']
  
  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end
  
  def send_confirmation_email
    ProblemMailer.deliver_problem_confirmation(reporter, self, token)
  end
  
  
  def validate_location_attributes
    return true if location
    if ! location_attributes_valid?
      errors.add(:location_attributes, ActiveRecord::Error.new(self, :location_attributes, :blank).to_s)
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
    if !location_attributes[:route_number].blank? and location_attributes[:name].blank?
      location_search.add_method('Gazetteer.find_routes_from_attributes') if location_search
      results = Gazetteer.find_routes_from_attributes(location_attributes, :limit => MAX_LOCATION_RESULTS)
    else
      location_search.add_method('Gazetteer.find_stops_from_attributes') if location_search
      results = Gazetteer.find_stops_from_attributes(location_attributes, :limit => MAX_LOCATION_RESULTS)
    end
    self.locations = results[:results]
    self.location_errors = results[:errors]
    if self.locations.empty? && self.location_errors.empty? 
      self.location_errors << :problem_location_not_found
    end
  end
  
  # campaigns usually start with no transport_mode
  def transport_mode_css_name
    return self.transport_mode.nil? ? 'none' : self.transport_mode.css_name
  end

end