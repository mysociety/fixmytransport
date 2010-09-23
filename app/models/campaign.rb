class Campaign < ActiveRecord::Base
  belongs_to :initiator, :class_name => 'User'
  has_many :campaign_supporters
  has_many :supporters, :through => :campaign_supporters, :class_name => 'User'
  belongs_to :location, :polymorphic => true
  belongs_to :transport_mode
  has_many :assignments
  has_one :problem
  has_many :incoming_messages
  after_create :add_default_assignment
  validates_presence_of :title, :description, :on => :update
  validates_associated :initiator, :on => :update
  named_scope :confirmed, :conditions => ['confirmed = ?', true], :order => 'created_at desc'
  has_friendly_id :title, :use_slug => true, :allow_nil => true
  cattr_reader :per_page, :categories
  @@per_page = 10
  @@categories = ['New route', 'Keep route', 'Get repair', 'Adopt', 'Other']
  
  has_status({ 0 => 'New', 
               1 => 'Confirmed', 
               2 => 'Successful',
               3 => 'Hidden' })

  # instance methods

  def add_default_assignment
    self.assignments.create(:user_id => initiator.id, :task_type_name => 'write-to-transport-operator')
  end
  
  def default_assignment
    self.assignments.first
  end
  
  def supporter_count
    campaign_supporters.confirmed.count
  end
  
  def add_supporter(user, confirmed=false)
    if ! supporters.include?(user)
      supporter_attributes = { :supporter => user }
      if confirmed 
        supporter_attributes[:confirmed_at] = Time.now
      end
      campaign_supporters.create(supporter_attributes)
    end
  end
  
  def remove_supporter(user)
    if supporters.include?(user)
      supporters.delete(user)
    end
  end
  
  def subdomain
    to_param
  end
  
  def domain  
    return "#{subdomain}.#{Campaign.email_domain}"
  end

  # class methods
  
  def self.find_by_campaign_email(email)
    local_part, domain = email.split("@")
    subdomain = domain.gsub(/\.#{email_domain}$/, '')
    campaign = find(:first, :conditions => ['cached_slug = ?', subdomain]) 
  end
  
  def self.email_domain
    MySociety::Config.get('INCOMING_EMAIL_DOMAIN', 'localhost')
  end
  
  def self.find_recent(number)
    confirmed.find(:all, :order => 'created_at desc', 
                         :limit => number, 
                         :include => [:location, :initiator])
  end
  
end
