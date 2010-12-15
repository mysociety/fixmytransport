class Problem < ActiveRecord::Base
  belongs_to :location, :polymorphic => true
  belongs_to :reporter, :class_name => 'User'
  belongs_to :transport_mode
  belongs_to :operator
  belongs_to :passenger_transport_executive
  belongs_to :campaign, :autosave => true
  has_many :assignments
  has_many :comments, :as => :commented
  has_many :sent_emails
  has_many :recipients, :through => :sent_emails
  validates_presence_of :description, :subject, :category, :reporter_name, :if => :location
  validates_length_of :reporter_name, :minimum => 5, :if => :location
  validate :validate_reporter_name
  validate :validate_is_campaign, :on => :create
  validates_associated :reporter
  attr_accessor :location_attributes, :locations, :location_search, :is_campaign
  cattr_accessor :route_categories, :stop_categories
  attr_protected :confirmed_at
  before_create :generate_confirmation_token
  has_status({ 0 => 'New', 
               1 => 'Confirmed', 
               2 => 'Fixed',
               3 => 'Hidden' })
  named_scope :confirmed, :conditions => ["status_code = ?", self.symbol_to_status_code[:confirmed]], :order => "confirmed_at desc"
  named_scope :visible, :conditions => ["status_code in (?)", [self.symbol_to_status_code[:confirmed], 
                                                              self.symbol_to_status_code[:fixed]]], :order => "confirmed_at desc"
  named_scope :unsent, :conditions => ['sent_at is null'], :order => 'confirmed_at desc'
  named_scope :with_operator, :conditions => ['operator_id is not null'], :order => 'confirmed_at desc'
  named_scope :one_off, :conditions => ['campaign_id is null']
  [:responsible_organizations, 
   :emailable_organizations, 
   :unemailable_organizations, 
   :councils_responsible?,
   :pte_responsible?,
   :operators_responsible? ].each { |method| delegate method, :to => :location }
  
  @@route_categories = ['New route needed', 'Keep existing route', 'Crowding', 'Lateness', 'Other']
  @@stop_categories = ['Repair needed', 'Facilities needed', 'Other']
  
  has_paper_trail
  
  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end
  
  def send_confirmation_email
    ProblemMailer.deliver_problem_confirmation(reporter, self, token)
  end
  
  def validate_reporter_name
    return true unless reporter_name
    return true unless location
    if /\ba\s*n+on+((y|o)mo?u?s)?(ly)?\b/i.match(reporter_name) or ! /\S\s\S/.match(reporter_name)
      errors.add(:reporter_name, ActiveRecord::Error.new(self, :reporter_name, :invalid).to_s)
    end
  end

  def validate_is_campaign
    return true if ['0','1'].include?(self.is_campaign)
    errors.add(:is_campaign, ActiveRecord::Error.new(self, :is_campaign, :blank).to_s)
  end
  
  def create_assignments
    assignment_types = []
    if assignments.empty? 
      assignment_types << { :name => 'publish-problem',
                            :status => :in_progress, 
                            :data => {} }
      assignment_types << { :name => 'write-to-transport-organization', 
                            :status => :in_progress, 
                            :data => {:organizations => organization_info(:responsible_organizations) }}
      if !responsible_organizations.empty? 
        if unemailable_organizations.size > 0
          assignment_types << { :name => 'find-transport-organization-contact-details', 
                                :status => :new, 
                                :data => {:organizations => organization_info(:unemailable_organizations) }}
        end
      else
        assignment_types << { :name => 'find-transport-organization', 
                              :status => :new, 
                              :data => {} }
      end
    end
    assignment_types.each do |data|
      assignment_attributes = { :task_type_name => data[:name], 
                                :status => data[:status],
                                :user => reporter,
                                :data => data[:data],
                                :problem => self }
      Assignment.create_assignment(assignment_attributes)
      
    end
  end
  
  def responsible_organizations
    if operators_responsible? && operator
      return [operator]
    end
    return location.responsible_organizations
  end
  
  def emailable_organizations
    responsible_organizations.select{ |organization| organization.emailable? }
  end
  
  def unemailable_organizations
    responsible_organizations.select{ |organization| !organization.emailable? }
  end
  
  def organization_info(method)
    self.send(method).map{ |organization| { :id => organization.id, 
                                            :type => organization.class.to_s, 
                                            :name => organization.name } }
  end
  
  def categories
    responsible_organizations.map{ |organization| organization.categories }.flatten.uniq
  end
  
  def recipients
    self.sent_emails.collect { |sent_email| sent_email.recipient }
  end
  
  # if this email has never been used before, assign the name 
  def reporter_attributes=(attributes)
    self.reporter = User.find_or_initialize_by_email(:email => attributes[:email], :name => reporter_name)
  end
  
  def confirm!
    return unless self.status == :new
    # complete the relevant assignments
    Assignment.complete_problem_assignments(self, {'publish-problem' => {}})
    data = {:organizations => self.organization_info(:responsible_organizations) }
    Assignment.complete_problem_assignments(self, {'write-to-transport-organization' => data })
    # save new values without validation - don't want to validate any associated campaign yet
    self.update_attribute('status', :confirmed)
    self.update_attribute('confirmed_at', Time.now)
  end
  
  def save_reporter
    reporter.save_if_new
  end
  
  def reply_email
    if campaign
      reporter.campaign_email_address(campaign)
    else
      reporter.email
    end
  end
  
  def reply_name_and_email
    if campaign
      reporter.campaign_name_and_email_address(campaign)
    else
      reporter.name_and_email
    end
  end
  
  def optional_assignments
    [:write_to_transport_organization, 
     :ask_for_advice]
  end
  
  # class methods
  def self.latest(limit)
    one_off.visible.find(:all, :limit => limit)
  end
  
  # Sendable reports - confirmed, with operator, PTE, or council, but not sent
  def self.sendable
    confirmed.unsent.find(:all, :conditions => ['(operator_id is not null
                                                  OR council_info is not null
                                                  OR passenger_transport_executive_id is not null)'])
  end
  
  def self.unsendable
    confirmed.unsent.find(:all, :conditions => ['(operator_id is null 
                                                  AND council_info is null 
                                                  AND passenger_transport_executive_id is null)'])
  end
  
end