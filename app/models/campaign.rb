class Campaign < ActiveRecord::Base
  belongs_to :initiator, :class_name => 'User'
  has_many :campaign_supporters
  has_many :supporters, :through => :campaign_supporters, :class_name => 'User', :conditions => ['campaign_supporters.confirmed_at is not null']
  belongs_to :location, :polymorphic => true
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
  validates_length_of :title, :within => 30..80, :on => :update
  validates_presence_of :description, :on => :update
  validates_associated :initiator, :on => :update
  cattr_reader :per_page
  delegate :transport_mode_text, :to => :problem
  accepts_nested_attributes_for :campaign_photos, :allow_destroy => true
  after_create :generate_key
  has_friendly_id :title,
                  :use_slug => true,
                  :allow_nil => true,
                  :max_length => 50

  has_paper_trail

  @@per_page = 10

  has_status({ 0 => 'New',
               1 => 'Confirmed',
               2 => 'Successful',
               3 => 'Hidden' })

  def self.visible_status_codes
   [self.symbol_to_status_code[:confirmed], self.symbol_to_status_code[:successful]]
  end

  named_scope :visible, :conditions => ["status_code in (?)", Campaign.visible_status_codes]

  # instance methods

  def confirm
    return unless self.status == :new
    self.status = :confirmed
    self.confirmed_at = Time.now
  end

  def visible?
    [:confirmed, :successful].include?(self.status)
  end

  def editable?
    [:new, :confirmed, :successful].include?(self.status)
  end

  def supporter_count
    campaign_supporters.confirmed.count
  end

  def recommended_assignments
    priority_assignments = ['find_transport_organization',
                            'find_transport_organization_contact_details']
    recommended_assignments =  self.assignments.select do |assignment|
      assignment.status == :new && priority_assignments.include?(assignment.task_type)
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
    if problem.operators_responsible?
      if problem.operator
        problem.operator.name
      else
        I18n.translate('campaigns.show.location_operator', :location => problem.location.description)
      end
    elsif problem.pte_responsible?
      problem.passenger_transport_executive.name
    elsif problem.councils_responsible?
      problem.responsible_organizations.map{ |org| org.name }.to_sentence
    end
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

  def call_to_action
    I18n.translate('campaigns.show.call_to_action', :org => self.responsible_org_descriptor, :title => self.title)
  end

  def short_call_to_action
    I18n.translate('campaigns.show.short_call_to_action', :title => self.title)
  end

  def short_initiator_call_to_action
    I18n.translate('campaigns.show.initiator_call_to_action', :title => self.title)
  end

  def supporter_call_to_action
    I18n.translate('campaigns.show.supporter_call_to_action', :org => self.responsible_org_descriptor, :title => self.title)
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
    problem.recipients.select{ |recipient| ! recipient.deleted? }
  end

  # get an array of assignments for the 'write-to-other' assignments
  # associated with this campaign
  def write_to_other_assignments
    assignments.find(:all, :conditions => ['task_type_name = ?', 'write-to-other'])
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

  def self.find_by_campaign_email(email)
    local_part, domain = email.split("@")
    key = local_part.downcase
    prefix = MySociety::Config.get("INCOMING_EMAIL_PREFIX", 'campaign-')
    key = key.gsub(/^#{prefix}/, '')
    campaign = find(:first, :conditions => ['lower(key) = ?', key])
  end

  def self.email_domain
    MySociety::Config.get('INCOMING_EMAIL_DOMAIN', 'localhost')
  end



end
