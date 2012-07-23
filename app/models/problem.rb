class Problem < ActiveRecord::Base

  include FixMyTransport::Status

  belongs_to :location, :polymorphic => true
  belongs_to :reporter, :class_name => 'User'
  belongs_to :transport_mode
  belongs_to :campaign, :autosave => true
  belongs_to :reference, :class_name => 'Problem'
  has_many :subscriptions, :as => :target
  has_many :subscribers, :through => :subscriptions, :source => :user
  has_many :assignments
  has_many :comments, :as => :commented
  has_many :sent_emails
  has_many :responsibilities
  has_many :questionnaires, :as => :subject
  has_many :external_questionnaires, :as => :subject
  has_and_belongs_to_many :guides
  validates_presence_of :description, :subject, :category, :if => :location
  validates_associated :reporter

  attr_accessible :subject, :description, :category,
                  :location_id, :location_type, :responsibilities_attributes,
                  :reference_id
  before_create :generate_confirmation_token, :add_coords
  has_status({ 0 => 'New',
               1 => 'Confirmed',
               2 => 'Fixed',
               3 => 'Hidden' })
  accepts_nested_attributes_for :responsibilities, :allow_destroy => true

  def self.visible_status_codes
    [self.symbol_to_status_code[:confirmed], self.symbol_to_status_code[:fixed]]
  end

  named_scope :confirmed, :conditions => ["problems.status_code = ?",
                                          self.symbol_to_status_code[:confirmed]],
                          :order => "confirmed_at desc"
  named_scope :visible, :conditions => ["problems.status_code in (?) and campaign_id is null",
                                        Problem.visible_status_codes],
                        :order => "confirmed_at desc"
  named_scope :unsent, :conditions => ['problems.sent_at is null'],
                       :order => 'confirmed_at desc'
  named_scope :sent, :conditions => ['problems.sent_at is not null'],
                     :order => 'confirmed_at desc'

  has_paper_trail

  # set attributes to include and exclude when performing model diffs
  diff :exclude => [:updated_at]

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

  def update_assignments
    # if there are now responsible organizations, remove any untried assignment to find
    # out who's responsible
    if !self.responsible_organizations.empty?
      find_org_assignments = self.assignments.is_new.find(:all, :conditions => ["task_type_name = 'find-transport-organization'"])
      find_org_assignments.each do |assignment|
        assignment.destroy
      end
    end
    # if there's an incomplete 'write-to-transport-organization' assignment, and
    # emailable organizations, complete it
    if !self.emailable_organizations.empty?
      data = { :organizations => self.organization_info(:responsible_organizations) }
      Assignment.complete_problem_assignments(self, {'write-to-transport-organization' => data })
    end
    return true
  end

  def responsible_organizations
    self.responsibilities.map{ |responsibility| responsibility.organization }
  end

  def responsible_operators
    self.responsible_organizations.select{ |org| org.is_a?(Operator) }
  end

  def responsible_org_descriptor
    if self.responsible_organizations.empty?
      I18n.translate('shared.problem.location_operator', :location => self.location.description)
    else
      self.responsible_organizations.map{ |org| org.name }.to_sentence
    end
  end

  def operator_names
    self.responsible_operators.map{ |operator| operator.name }.to_sentence
  end

  def emailable_organizations
    self.responsible_organizations.select{ |organization| organization.emailable?(self.location) }
  end

  def unemailable_organizations
    self.responsible_organizations.select{ |organization| !organization.emailable?(self.location) }
  end

  def organization_info(method)
    self.send(method).map{ |organization| { :id => organization.id,
                                            :type => organization.class.to_s,
                                            :name => organization.name } }
  end

  def recipient_contact(recipient)
    if [Council, Operator, PassengerTransportExecutive].include?(recipient.class)
      return recipient.contact_for_category_and_location(category, location)
    else
      raise "Unknown recipient type: #{recipient.class.to_s}"
    end
  end

  def recipient_emails(recipient)
    # on a staging site, don't send live emails
    if MySociety::Config.getbool('STAGING_SITE', true)
      return { :to => MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost') }
    elsif self.location.is_a?(Route) && self.location.number == 'ZZ9'
      return { :to => MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost') }
    else
      contact = self.recipient_contact(recipient)
      emails = { :to => contact.email }
      if contact.respond_to?(:cc_email) && !contact.cc_email.blank?
        emails[:cc] = contact.cc_email
      end
      return emails
    end
  end

  def categories
    if self.reference
      orgs = self.reference.responsible_organizations
    else
      orgs = self.location.responsible_organizations
    end
    orgs.map{ |organization| organization.categories(self.location) }.flatten.uniq.sort
  end

  def recipients
    self.reports_sent.map{ |sent_email| sent_email.recipient }.compact.uniq
  end

  def reports_sent
    self.sent_emails.select{ |sent_email| sent_email if !sent_email.comment_id }
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
    self.update_attribute('confirmed_at', Time.now) unless self.confirmed_at
    # create a subscription for the problem reporter if one doesn't exist
    if Subscription.find_for_user_and_target(self.reporter, self.id, self.class.to_s).nil?
      Subscription.create!(:user => self.reporter, :target => self, :confirmed_at => Time.now)
    end
  end

  def create_new_campaign
    return self.campaign if self.campaign
    campaign = self.build_campaign()
    campaign.initiator = self.reporter
    campaign.problem = self
    campaign.title = "#{I18n.translate("models.campaign.fix_this")} #{self.subject}"
    campaign.description = self.description
    campaign.location_id = self.location_id
    campaign.location_type = self.location_type
    campaign.status = :new
    campaign.confirm
    self.save
    return campaign
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

  def fixed?
    self.status == :fixed
  end

  def confirmed_and_visible?
    self.status == :confirmed
  end

  def visible?
    [:confirmed, :fixed].include?(self.status)
  end

  def sendable?
    (self.status == :confirmed && self.sent_at.nil? && !self.responsibilities.empty?)
  end

  def unsendable?
    (self.status == :confirmed && self.sent_at.nil? && self.responsibilities.empty?)
  end

  # Return a list of version models in cronological order representing changes made
  # in the admin interface to this problem or associated responsibilities
  def admin_actions
    Version.find(:all, :conditions => ["admin_action = ?
                                        AND ((item_type = 'Responsibility'
                                        AND problem_id = ?) OR
                                        (item_type = 'Problem'
                                        AND item_id = ?))", true, id, id],
                       :order => "id asc")
  end

  # class methods

  def self.find_issues_in_bounding_box(coords)
    bounding_box_clause = "AND problems.coords && ST_Transform(ST_SetSRID(ST_MakeBox2D(
                           ST_Point(#{coords[:left]}, #{coords[:bottom]}),
                           ST_Point(#{coords[:right]}, #{coords[:top]})), #{WGS_84}), #{BRITISH_NATIONAL_GRID})"
    issues = self.find_recent_issues(nil, :other_condition => bounding_box_clause)
    locations = {}
    problem_ids = []
    stop_ids = []
    stop_area_ids = []
    issues.each do |issue|
      case issue
      when Problem
        problem_ids << issue.id
      when Campaign
        problem_ids << issue.problem.id
      end
      location = issue.location
      location_key = "#{location.class}_#{location.id}"
      if !locations.has_key?(location_key)
        case location
        when Stop
          stop_ids << location.id
        when StopArea
          stop_area_ids << location.id
        end
        location.highlighted = true
        locations[location_key] = location
      end
    end
    { :locations => locations.values,
      :issues => issues,
      :problem_ids => problem_ids,
      :stop_ids => stop_ids,
      :stop_area_ids => stop_area_ids }
  end

  # find issues within a radius expressed in km
  def self.find_nearest_issues(lat, lon, distance, options)
    conn = self.connection
    distance_clause = "ST_Distance(
                        ST_Transform(
                          ST_GeomFromText('POINT(#{conn.quote(lon)} #{conn.quote(lat)})', #{WGS_84}),
                        #{BRITISH_NATIONAL_GRID}),
                      coords)"
    conditions = "AND #{distance_clause} < #{distance * 1000}"
    if options[:exclude_ids] && !options[:exclude_ids].empty?
      ids = options[:exclude_ids].map{ |id| conn.quote(id) }.join(",")
      conditions += " AND problems.id not in (#{ids})"
    end
    order = "order by #{distance_clause} asc"
    self.find_recent_issues(nil, :other_condition => conditions,
                                 :order_clause => order)
  end

  def self.create_from_hash(data, user, token=nil)
    if data[:text_encoded] == true
      description = ActiveSupport::Base64.decode64(data[:description])
    else
      description = data[:description]
    end
    problem = Problem.new(:subject => data[:subject],
                          :description => description,
                          :location_id => data[:location_id],
                          :location_type => data[:location_type],
                          :category => data[:category])
    data[:responsibilities].split(",").each do |responsibility_string|
      organization_id, organization_type = responsibility_string.split("|")
      problem.responsibilities.build(:organization_id => organization_id,
                                     :organization_type => organization_type)
    end
    problem.status = :new
    problem.reporter = user
    problem.save!
    if token
      problem.update_attribute(:token, token)
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

    if options[:other_condition]
      other_condition_clause = options[:other_condition]
    else
      other_condition_clause = ''
    end

    if options[:order_clause]
      order_clause = options[:order_clause]
    else
      order_clause = 'ORDER by latest_date desc'
    end

    if options.fetch(:date_to_use, '') == 'creation'
      problem_date_column = 'problems.created_at'
      campaign_date_column = 'campaigns.created_at'
    else
      problem_date_column = 'problems.updated_at'
      campaign_date_column = 'campaigns.latest_event_at'
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
      if location_class == "'Route'" && !location.sub_routes.empty?
        # for a train route, we want to include problems on sub-routes of this route
        # that were reported to a matching operator
        operator_ids = location.operator_ids.map{ |id| conn.quote(id) }.join(',')
        extra_tables = ", responsibilities"
        location_clause = "AND ((problems.location_id = #{location_id}
                            AND problems.location_type = #{location_class})
                            OR
                            (problems.location_id in (SELECT sub_route_id
                                             FROM route_sub_routes
                                             WHERE route_id = #{location_id})
                             AND problems.location_type = 'SubRoute'
                             AND problems.id = responsibilities.problem_id
                             AND responsibilities.organization_type = 'Operator'
                             AND responsibilities.organization_id in (#{operator_ids}))) "
      else
        extra_tables = ''
        location_clause = " AND problems.location_id = #{location_id}
                            AND problems.location_type = #{location_class} "
      end
    elsif options[:single_operator]
      operator = options[:single_operator]
      extra_tables = ", responsibilities"
      location_clause = "AND problems.id = responsibilities.problem_id
                         AND responsibilities.organization_type = 'Operator'
                         AND responsibilities.organization_id = #{operator.id} "
    else
      extra_tables = ''
      location_clause = ""
    end
    # grab the ids of visible campaigns and problems, order them by most recently created
    # (problems) or active (campaigns)
    visible_problem_codes = Problem.visible_status_codes.map{ |code| conn.quote(code) }.join(",")
    visible_campaign_codes = Campaign.visible_status_codes.map{ |code| conn.quote(code) }.join(",")
    issue_info = self.connection.select_rows("SELECT id, model_type
                                             FROM
                                             (SELECT problems.id, 'Problem' as model_type, #{problem_date_column} as latest_date, coords
                                              FROM problems #{extra_tables}
                                              WHERE status_code in (#{visible_problem_codes})
                                              AND campaign_id is null
                                              #{location_clause}
                                              #{other_condition_clause}
                                              UNION
                                              SELECT campaigns.id, 'Campaign' as model_type, #{campaign_date_column} as latest_date, coords
                                              FROM campaigns, problems #{extra_tables}
                                              WHERE campaigns.status_code in (#{visible_campaign_codes})
                                              #{location_clause}
                                              #{other_condition_clause}
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

  # Sendable reports - confirmed, with responsible_organizations, but not sent
  def self.sendable
    confirmed.unsent.find(:all, :include => :responsibilities,
                                :conditions => ['responsibilities.id is not null'])
  end

  def self.unsendable
    confirmed.unsent.find(:all, :include => :responsibilities,
                                :conditions => ['responsibilities.id is null'])
  end

  def self.needing_questionnaire(weeks_ago, user=nil)
    time_weeks_ago = Time.now - weeks_ago.weeks
    params = [time_weeks_ago, true, time_weeks_ago]
    if user
      user_clause = " AND reporter_id = ?"
      params << user
    else
      user_clause = ""
    end
    query = ["problems.sent_at < ?
              AND send_questionnaire = ?
              AND ((SELECT max(completed_at)
                    FROM questionnaires
                    WHERE subject_type = 'Problem'
                    AND subject_id = problems.id) < ?
                   OR (SELECT max(completed_at)
                    FROM questionnaires
                    WHERE subject_type = 'Problem'
                    AND subject_id = problems.id) is NULL)
                    #{user_clause}"]
    self.visible.sent.find(:all, :conditions => query + params)
  end

  def feed_title_suffix
    :fixed == status ? " [FIXED]" : ""
  end

end
