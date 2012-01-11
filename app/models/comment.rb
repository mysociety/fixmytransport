class Comment < ActiveRecord::Base

  include FixMyTransport::Status

  belongs_to :user, :counter_cache => true
  belongs_to :commented, :polymorphic => true
  validates_presence_of :text
  validates_presence_of :user_name, :unless => :skip_name_validation
  validates_associated :user
  before_create :generate_confirmation_token
  before_validation_on_create :populate_user_name
  has_many :campaign_events, :as => :described
  attr_accessor :skip_name_validation, :old_commented_status_code
  named_scope :unsent, :conditions => ['sent_at is null']
  attr_accessible :text, :user, :mark_fixed, :mark_open
  has_paper_trail
  has_status({ 0 => 'New',
               1 => 'Confirmed',
               2 => 'Hidden' })

  named_scope :visible, :conditions => ["status_code = ?", self.symbol_to_status_code[:confirmed]], :order => "confirmed_at asc"

  # set attributes to include and exclude when performing model diffs
  diff :exclude => [:updated_at]

  def visible?
    self.status_code == self.symbol_to_status_code[:confirmed]
  end

  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end

  def populate_user_name
    if self.user and ! self.user_name
      self.user_name = self.user.name
    end
  end

  # create the user if it doesn't exist, but don't save it yet
  def user_attributes=(attributes)
    if !attributes[:id].blank?
      self.user = User.find(attributes[:id])
    else
      self.user = User.find_or_initialize_by_email(attributes[:email], :name => user_name)
    end
  end

  def save_user
    user.save_if_new
  end
  
  def user_marks_as_fixed?
    self.commented.is_a?(Problem) && self.user == self.commented.reporter && self.mark_fixed
  end
  
  def confirm!
    return unless self.status == :new
    ActiveRecord::Base.transaction do
      self.status = :confirmed
      self.confirmed_at = Time.now
      if self.commented.is_a? Problem
        if self.mark_fixed
          # store the old issue status so we can record it if
          # the user fills in the 'reported before' questionnaire
          self.old_commented_status_code = self.commented.status_code
          self.commented.status = :fixed
          if self.user == self.commented.reporter
            self.commented.send_questionnaire = false
          end
        end
        if mark_open && self.user == commented.reporter
          self.commented.status = :confirmed
        end
        self.commented.updated_at = Time.now
        self.commented.save!
      elsif commented.is_a? Campaign
        self.campaign_events.build(:event_type => 'comment_added',
                                   :described => self,
                                   :campaign => commented)
      end
      save!
    end
  end

  # Return a list of version models in cronological order representing changes made
  # in the admin interface to this comment
  def admin_actions
    self.versions.find(:all, :conditions => ['admin_action = ?', true])
  end

  # class methods
  def self.create_from_hash(data, user, token=nil)
    if data[:text_encoded] == true
      text = ActiveSupport::Base64.decode64(data[:text])
    else
      text = data[:text]
    end
    comment = data[:model].comments.build(:text => text,
                                          :user => user,
                                          :mark_fixed => data[:mark_fixed],
                                          :mark_open => data[:mark_open])
    comment.status = :new
    comment.save
    if data[:confirmed]
      comment.confirm!
    end
    if token
      comment.update_attribute(:token, token)
    end
    comment
  end

end
