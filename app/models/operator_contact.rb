class OperatorContact < ActiveRecord::Base
  # This association uses custom keys as the object associated is scoped by data generations - a
  # persistent id may be held by a different model instance in each generation
  belongs_to :operator, :foreign_key => :operator_persistent_id,
                        :primary_key => :persistent_id
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  validates_presence_of :category
  belongs_to :location, :polymorphic => true
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  validates_format_of :cc_email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$"), :allow_blank => true
  validates_uniqueness_of :category, :scope => [:operator_persistent_id,
                                                :deleted,
                                                :location_id,
                                                :location_type],
                                       :if => Proc.new{ |contact| ! contact.deleted? }
  has_paper_trail


  def name
    operator.name
  end

  def last_editor
    return nil if versions.empty?
    return versions.last.whodunnit
  end

  # at the moment operator contacts can only relate to stations
  def stop_area_id=(location_id)
    self.location_id = location_id
    self.location_type = 'StopArea'
  end

  def stop_area_id()
    self.location_id
  end

  def self.contacts_missing_operators
    self.find(:all, :conditions => ['operator_persistent_id NOT IN (SELECT persistent_id
                                                                    FROM operators
                                                                    WHERE generation_low <= ?
                                                                    AND generation_high >= ?)',
                                                                    CURRENT_GENERATION,
                                                                    CURRENT_GENERATION])
  end

end
