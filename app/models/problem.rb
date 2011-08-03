class Problem < ActiveRecord::Base
  belongs_to :location, :polymorphic => true
  belongs_to :reporter, :class_name => 'User'
  belongs_to :transport_mode
  belongs_to :operator
  belongs_to :passenger_transport_executive
  belongs_to :campaign, :autosave => true
  has_many :subscriptions, :as => :target
  has_many :subscribers, :through => :subscriptions, :source => :user
  has_many :assignments
  has_many :comments, :as => :commented
  has_many :sent_emails
  validates_presence_of :description, :subject, :category, :if => :location
  validates_associated :reporter
  validates_presence_of :operator_id, :if => :location_has_operators
  attr_accessor :location_attributes, :locations, :location_search, :is_campaign
  attr_protected :confirmed_at
  before_create :generate_confirmation_token, :add_coords
  has_status({ 0 => 'New',
               1 => 'Confirmed',
               2 => 'Fixed',
               3 => 'Hidden' })

  def self.visible_status_codes
    [self.symbol_to_status_code[:confirmed], self.symbol_to_status_code[:fixed]]
  end

  named_scope :confirmed, :conditions => ["status_code = ?", self.symbol_to_status_code[:confirmed]], :order => "confirmed_at desc"
  named_scope :visible, :conditions => ["status_code in (?) and campaign_id is null", Problem.visible_status_codes], :order => "confirmed_at desc"
  named_scope :unsent, :conditions => ['sent_at is null'], :order => 'confirmed_at desc'
  named_scope :with_operator, :conditions => ['operator_id is not null'], :order => 'confirmed_at desc'
  [:responsible_organizations,
   :emailable_organizations,
   :unemailable_organizations,
   :councils_responsible?,
   :pte_responsible?,
   :operators_responsible? ].each { |method| delegate method, :to => :location }

  has_paper_trail

  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end

  def add_coords
    self.lat = self.location.lat
    self.lon = self.location.lon
    self.coords = self.location.coords
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
                                :problem => self,
                                :campaign => self.campaign }
      Assignment.create_assignment(assignment_attributes)

    end
  end

  def location_has_operators
    operators_responsible? && location.operators.size > 0
  end

  def responsible_organizations
    if operators_responsible? && operator
      return [operator]
    end
    return location.responsible_organizations
  end

  def emailable_organizations
    responsible_organizations.select{ |organization| organization.emailable?(self.location) }
  end

  def unemailable_organizations
    responsible_organizations.select{ |organization| !organization.emailable?(self.location) }
  end

  def organization_info(method)
    self.send(method).map{ |organization| { :id => organization.id,
                                            :type => organization.class.to_s,
                                            :name => organization.name } }
  end

  def categories
    responsible_organizations.map{ |organization| organization.categories(self.location) }.flatten.uniq
  end

  def recipients
    self.sent_emails.collect{ |sent_email| sent_email.recipient if !sent_email.comment_id }.compact.uniq
  end

  # if this email has never been used before, assign the name
  def reporter_attributes=(attributes)
    self.reporter = User.find_or_initialize_by_email(:email => attributes[:email], :name => reporter_name)
  end

  def confirm!
    return unless self.status == :new
    # complete the relevant assignments
    self.create_assignments
    self.assignments.each do |assignment|
      assignment.update_attribute('campaign', campaign)
    end
    Assignment.complete_problem_assignments(self, {'publish-problem' => {}})
    data = {:organizations => self.organization_info(:responsible_organizations) }
    if !self.emailable_organizations.empty?
      Assignment.complete_problem_assignments(self, {'write-to-transport-organization' => data })
    end
    # save new values without validation - don't want to validate any associated campaign yet
    self.update_attribute('status', :confirmed)
    self.update_attribute('confirmed_at', Time.now)
    # create a subscription for the problem reporter
    Subscription.create!(:user => self.reporter, :target => self, :confirmed_at => Time.now)
  end

  def create_new_campaign
    return self.campaign if self.campaign
    campaign = self.build_campaign({ :location_id => self.location_id,
                                     :location_type => self.location_type,
                                     :initiator => self.reporter,
                                     :problem => self })
    campaign.status = :new
    self.save
    return campaign
  end

  def save_reporter
    reporter.save_if_new
  end

  def reply_email
    if campaign
      campaign.email_address
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

  def transport_mode_text
    location.transport_modes.map{ |transport_mode| transport_mode.name }.join(", ")
  end

  def visible?
    [:confirmed, :fixed].include?(self.status)
  end

  # class methods

  def self.find_issues_in_bounding_box(min_lat, min_lon, max_lat, max_lon, options={})
    bounding_box_clause = "AND problems.coords && ST_Transform(ST_SetSRID(ST_MakeBox2D(
                           ST_Point(#{min_lon}, #{min_lat}),
                           ST_Point(#{max_lon}, #{max_lat})), #{WGS_84}), #{BRITISH_NATIONAL_GRID})"
    issues = self.find_recent_issues(nil, :bounding_box => bounding_box_clause)
    locations = {}
    issues.each do |issue|
      location = issue.location
      location_key = "#{location.class}_#{location.id}"
      if !locations.has_key?(location_key)
        location.highlighted = true
        locations[location_key] = location
      end
    end
    { :locations => locations.values, :issues => issues }
  end

  def self.find_nearest_issues(lat, lon, limit, options={})
    order_clause = "order by ST_Distance(
                    ST_Transform(ST_GeomFromText('POINT(#{lon} #{lat})', #{WGS_84}), #{BRITISH_NATIONAL_GRID}),
                    coords) asc"
    issues = self.find_recent_issues(limit, :order_clause => order_clause)
  end

  def self.create_from_hash(data, user, token=nil)
    problem = Problem.new(:subject => data[:subject],
                          :description => data[:description],
                          :location_id => data[:location_id],
                          :location_type => data[:location_type],
                          :category => data[:category],
                          :operator_id => data[:operator_id],
                          :passenger_transport_executive_id => data[:passenger_transport_executive_id],
                          :council_info => data[:council_info])
    problem.status = :new
    problem.reporter = user
    problem.reporter_name = user.name
    problem.save!
    if token
      problem.update_attributes(:token => token)
    end
    return problem
  end

  # Get a number of recent problems and campaigns, with an optional offset
  def self.find_recent_issues(number, options={})
    conn = self.connection
    if number
      limit_clause = " LIMIT #{conn.quote(number)} "
    else
      limit_clause = ""
    end

    if options[:offset]
      offset_clause = " OFFSET #{conn.quote(options[:offset])}"
    else
      offset_clause = ""
    end

    if options[:bounding_box]
      bounding_box_clause = options[:bounding_box]
    else
      bounding_box_clause = ''
    end

    if options[:order_clause]
      order_clause = options[:order_clause]
    else
      order_clause = 'ORDER by latest_date desc'
    end

    if options[:location]
      location = options[:location]
      location_id = conn.quote(location.id)
      # make sure we have 'Route' for routes, not one of it's subclasses
      if location.class.superclass == ActiveRecord::Base
        location_class = location.class.to_s
      else
        location_class = location.class.superclass.to_s
      end
      location_class = conn.quote(location_class)
      if location_class == 'Route' && !location.sub_routes.empty?
        # for a train route, we want to include problems on sub-routes of this route
        # that were reported to a matching operator
        operator_ids = location.operator_ids.map{ |id| conn.quote(id) }.join(',')
        location_clause = "AND ((problems.location_id = #{location_id}
                            AND problems.location_type = #{location_class})
                            OR
                            (problems.location_id in (SELECT sub_route_id
                                             FROM route_sub_routes
                                             WHERE route_id = #{location_id})
                             AND problems.location_type = 'SubRoute'
                             AND problems.operator_id in (#{operator_ids}))) "
      else
        location_clause = " AND problems.location_id = #{location_id}
                            AND problems.location_type = #{location_class} "
      end
    else
      location_clause = ""
    end
    # grab the ids of visible campaigns and problems, order them by most recently created
    # (problems) or active (campaigns)
    visible_problem_codes = Problem.visible_status_codes.map{ |code| conn.quote(code) }.join(",")
    visible_campaign_codes = Campaign.visible_status_codes.map{ |code| conn.quote(code) }.join(",")
    issue_info = self.connection.select_rows("SELECT id, model_type
                                             FROM
                                             (SELECT id, 'Problem' as model_type, confirmed_at as latest_date, coords
                                              FROM problems
                                              WHERE status_code in (#{visible_problem_codes})
                                              AND campaign_id is null
                                              #{location_clause}
                                              #{bounding_box_clause}
                                              UNION
                                              SELECT campaigns.id, 'Campaign' as model_type, latest_event_at as latest_date, coords
                                              FROM campaigns, problems
                                              WHERE campaigns.status_code in (#{visible_campaign_codes})
                                              #{location_clause}
                                              #{bounding_box_clause}
                                              AND problems.campaign_id = campaigns.id
                                              )
                                             AS campaigns_and_problems
                                             #{order_clause}
                                             #{limit_clause}
                                             #{offset_clause}")
    campaign_ids = {}
    problem_ids = {}
    # store the index that each id sits at in date order
    issue_info.each_with_index do |issue, index|
      if issue[1] == 'Problem'
        problem_ids[issue[0].to_i] = index
      else
        campaign_ids[issue[0].to_i] = index
      end
    end
    issues = []
    # pull all the models with the associations we need for displaying them
    problems = Problem.find(:all, :conditions => ['id in (?)', problem_ids.keys],
                                  :include => [:location, :reporter])
    campaigns = Campaign.find(:all, :conditions => ['id in (?)', campaign_ids.keys],
                                    :include => [:location, :initiator])
    # map the models back into the a combined array in the right order
    problems.each{ |problem| issues[problem_ids[problem.id]] = problem }
    campaigns.each{ |campaign| issues[campaign_ids[campaign.id]] = campaign }
    return issues
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