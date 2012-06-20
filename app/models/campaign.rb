class Campaign < ActiveRecord::Base

  include FixMyTransport::Status

  belongs_to :initiator, :class_name => 'User'
  has_many :campaign_supporters
  has_many :supporters, :through => :campaign_supporters, :class_name => 'User', :conditions => ['campaign_supporters.confirmed_at is not null']
  belongs_to :transport_mode
  has_many :assignments
  has_one :problem
  has_many :incoming_messages
  has_many :outgoing_messages
  has_many :campaign_updates
  has_many :comments, :as => :commented, :order => 'confirmed_at asc'
  has_many :campaign_events, :order => 'created_at asc'
  has_many :campaign_photos
  has_many :subscriptions, :as => :target
  has_many :subscribers, :through => :subscriptions, :source => :user, :conditions => ['subscriptions.confirmed_at is not null']
  has_many :questionnaires, :as => :subject
  has_and_belongs_to_many :guides
  validates_length_of :title, :maximum => 80, :on => :update, :allow_nil => true
  validates_presence_of :title, :description, :on => :update
  validates_format_of :title, :with => /^.*(?=.*[a-zA-Z]).*$/,
                              :on => :update,
                              :allow_nil => true
  validates_associated :initiator, :on => :update
  cattr_reader :per_page
  delegate :transport_mode_text, :to => :problem
  accepts_nested_attributes_for :campaign_photos, :allow_destroy => true
  after_create :generate_key
  attr_accessible :title, :description, :campaign_photos_attributes
  has_friendly_id :title,
                  :use_slug => true,
                  :allow_nil => true,
                  :max_length => 36

  has_paper_trail

  # set attributes to include and exclude when performing model diffs
  diff :exclude => [:updated_at]

  # pagination default
  @@per_page = 10

  has_status({ 0 => 'New',
               1 => 'Confirmed',
               2 => 'Fixed',
               3 => 'Hidden' })

  def self.visible_status_codes
   [self.symbol_to_status_code[:confirmed], self.symbol_to_status_code[:fixed]]
  end

  named_scope :visible, :conditions => ["campaigns.status_code in (?)", Campaign.visible_status_codes]

  # instance methods

  def handle_location_responsibility_change(organizations)
    event_data = {:organization_names => organizations.map{ |organization| organization.name }}
    campaign_events.create!(:event_type => 'location_responsibility_changed',
                            :data => event_data)
    organizations.each do |organization|
      draft_text = "\n\n-----#{I18n.translate('outgoing_messages.new.original_message')}-----\n\n"
      draft_text += self.problem.description
      assignment_attributes = { :task_type_name => 'write-to-new-transport-organization',
                                :status => :new,
                                :user => self.problem.reporter,
                                :data => { :organization_name => organization.name,
                                           :organization_type => organization.class.to_s,
                                           :organization_persistent_id => organization.persistent_id,
                                           :draft_text => draft_text },
                                :problem => self.problem,
                                :campaign => self }
      Assignment.create_assignment(assignment_attributes)
    end
  end

  def location=(new_location)
    self.location_type = new_location.class.base_class.name.to_s
    self.location_persistent_id = new_location.persistent_id
  end

  def location
    self.location_type.constantize.current.find_by_persistent_id(self.location_persistent_id)
  end

  def confirm
    return unless self.status == :new
    self.status = :confirmed
    self.confirmed_at = Time.now
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

  def editable?
    [:new, :confirmed, :fixed].include?(self.status)
  end

  def supporter_count
    campaign_supporters.confirmed.count
  end

  def recommended_assignments
    priority_assignments = ['find_transport_organization',
                            'find_transport_organization_contact_details',
                            'write_to_new_transport_organization']
    recommended_assignments =  self.assignments.select do |assignment|
      assignment.status == :new && priority_assignments.include?(assignment.task_type) && assignment.valid?
    end
    recommended_assignments
  end

  def assignments_with_contacts
    assignments_with_contacts = self.assignments.select do |assignment|
      assignment.task_type == 'write_to_other'
    end
    assignments_with_contacts
  end

  def responsible_org_descriptor
    problem.responsible_org_descriptor
  end

  # Add a user as a supporter of a campaign
  # if a token is passed, set the token on the CampaignSupporter model.
  # If the user is already a supporter or initiator of the campaign,
  # nil is returned.
  # Also create a subscription for the user to the campaign
  def add_supporter(user, supporter_confirmed=false, token=nil)
    if ! self.supporters.include?(user) && user != self.initiator
      supporter_attributes = { :supporter => user }
      subscription_attributes = { :user => user }
      if supporter_confirmed
        supporter_attributes[:confirmed_at] = Time.now
        subscription_attributes[:confirmed_at] = Time.now
      end
      campaign_supporter = campaign_supporters.create!(supporter_attributes)
      subscription = subscriptions.create!(subscription_attributes)
      if token
        campaign_supporter.update_attributes(:token => token)
        subscription.update_attributes(:token => token)
      end
      return campaign_supporter
    else
      return nil
    end
  end

  def twitter_call_to_action
    I18n.translate('campaigns.show.twitter_call_to_action', :org => self.responsible_org_descriptor,
                                                            :title =>  MySociety::Format.lcfirst(self.title))
  end

  def call_to_action
    I18n.translate('campaigns.show.call_to_action', :org => self.responsible_org_descriptor,
                                                    :title =>  MySociety::Format.lcfirst(self.title))
  end

  def short_call_to_action
    I18n.translate('campaigns.show.short_call_to_action', :org => self.responsible_org_descriptor,
                                                          :title => MySociety::Format.lcfirst(self.title))
  end

  def short_initiator_call_to_action
    I18n.translate('campaigns.show.initiator_call_to_action', :org => self.responsible_org_descriptor,
                                                              :title => MySociety::Format.lcfirst(self.title))
  end

  def supporter_call_to_action
    I18n.translate('campaigns.show.supporter_call_to_action', :org => self.responsible_org_descriptor,
                                                              :title =>  MySociety::Format.lcfirst(self.title))
  end

  def remove_supporter(user)
    if supporters.include?(user)
      supporters.delete(user)
    end
    if subscribers.include?(user)
      subscribers.delete(user)
    end
  end

  def domain
    return Campaign.email_domain
  end

  def valid_local_parts
    [email_local_part]
  end

  def get_recipient(email_address)
    initiator
  end

  def existing_recipients
    problem.recipients.select{ |recipient| ! recipient.deleted_or_organization_deleted? }
  end

  # get an array of assignments for the 'write-to-other' assignments
  # associated with this campaign
  def write_to_other_assignments
    assignments.find(:all, :conditions => ['task_type_name = ?', 'write-to-other'])
  end

  # Return a list of version models in cronological order representing changes made
  # in the admin interface to this campaign
  def admin_actions
    self.versions.find(:all, :conditions => ['admin_action = ?', true])
  end

  # Encode the id to Base 26 and then use alphabetic rather than alphanumeric range
  def email_id
    self.id.to_s(base=26).tr('0-9a-p', 'a-z')
  end

  def generate_key
    chars = ('a'..'z').to_a
    random_string = (0..5).map{ chars[rand(chars.length)] }.join
    generated_key = "#{email_id}-#{random_string}"
    self.update_attribute("key", generated_key)
    return generated_key
  end

  def email_address
    domain = MySociety::Config.get("INCOMING_EMAIL_DOMAIN", 'localhost')
    "#{email_local_part}@#{domain}"
  end

  def email_local_part
    prefix = MySociety::Config.get("INCOMING_EMAIL_PREFIX", 'campaign-')
    "#{prefix}#{key}"
  end

  # class methods
  def self.email_id_to_id(email_id)
    base_26_string = email_id.tr('a-z', '0-9a-p')
    base_26_string.to_i(base=26)
  end

  def self.mail_conf_staging_dir
    dir = "#{RAILS_ROOT}/data/mail_conf"
    FileUtils.mkdir_p(dir)
  end

  def self.key_from_email(email)
    local_part, domain = email.split("@")
    key = local_part.downcase
    prefix = MySociety::Config.get("INCOMING_EMAIL_PREFIX", 'campaign-')
    key = key.gsub(/^#{prefix}/, '')
  end

  # Return the campaign that an email address references
  def self.find_by_campaign_email(email)
    key = self.key_from_email(email)
    campaign = find(:first, :conditions => ['lower(key) = ?', key])
  end

  # Guess which campaign an email address references using only the encoded ID
  def self.guess_by_campaign_email(email)
    key = self.key_from_email(email)
    email_id, random_string = key.split('-')
    id = email_id_to_id(email_id)
    Campaign.find(:first, :conditions => ['id = ?', id])
  end

  def self.email_domain
    MySociety::Config.get('INCOMING_EMAIL_DOMAIN', 'localhost')
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
    query = ["problems.sent_at is not null
              AND problems.sent_at < ?
              AND campaigns.send_questionnaire = ?
              AND ((SELECT max(completed_at)
                   FROM questionnaires
                   WHERE subject_type = 'Campaign'
                   AND subject_id = campaigns.id) < ?
                   OR (SELECT max(completed_at)
                   FROM questionnaires
                   WHERE subject_type = 'Campaign'
                   AND subject_id = campaigns.id) is NULL)
                   #{user_clause}"]
    self.visible.find(:all, :conditions => query + params,
                            :include => :problem)
  end

  def feed_title_suffix
    :fixed == status ? " [FIXED]" : ""
  end

end
