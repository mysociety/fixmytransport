class Problem < ActiveRecord::Base
  belongs_to :location, :polymorphic => true
  belongs_to :reporter, :class_name => 'User'
  belongs_to :transport_mode
  belongs_to :operator
  has_many :assignments
  accepts_nested_attributes_for :reporter
  validates_presence_of :transport_mode_id, :unless => :location
  validates_presence_of :description, :subject, :category, :if => :location
  validate :validate_location_attributes
  attr_accessor :location_attributes, :locations, :location_search, :location_errors
  cattr_accessor :route_categories, :stop_categories
  after_create :send_confirmation_email
  before_create :generate_confirmation_token
  named_scope :confirmed, :conditions => ['confirmed = ?', true], :order => 'confirmed_at desc'
  named_scope :unsent, :conditions => ['sent_at is null'], :order => 'confirmed_at desc'
  named_scope :with_operator, :conditions => ['operator_id is not null'], :order => 'confirmed_at desc'
  
  @@route_categories = ['New route needed', 'Keep existing route', 'Crowding', 'Lateness', 'Other']
  @@stop_categories = ['Repair needed', 'Facilities needed', 'Other']
  
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
  
  def create_assignment
    assignment_types = []
    if assignments.empty? 
      if operator 
        if operator.email.blank?
          assignment_types << ['find-transport-operator-contact-details', :new]
          assignment_types << ['publish-problem', :in_progress]
        else  
          assignment_types << ['publish-problem', :in_progress]
          assignment_types << ['write-to-transport-operator', :in_progress]
        end
      else
        assignment_types << ['publish-problem', :in_progress]
        assignment_types << ['find-transport-operator', :new]
        assignment_types << ['find-transport-operator-contact-details', :new]
      end
    end
    assignment_types.each do |assignment_type, status|
      assignment_attributes = { :task_type_name => assignment_type, 
                                :status => status,
                                :user => reporter,
                                :problem => self }
      Assignment.create_assignment(assignment_attributes)
    end
  end
   
  # class methods
  # Sendable reports - confirmed, with operator, but not sent
  def self.sendable
    confirmed.with_operator.unsent
  end
  
  def self.categories(problem)
    if problem.location.is_a? Route 
      return route_categories
    else
      return stop_categories
    end
  end
end