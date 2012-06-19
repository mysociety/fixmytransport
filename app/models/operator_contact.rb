class OperatorContact < ActiveRecord::Base

  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  validates_presence_of :category
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  validates_format_of :cc_email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$"), :allow_blank => true
  validates_uniqueness_of :category, :scope => [:operator_persistent_id,
                                                :deleted,
                                                :location_persistent_id,
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

  def operator=(new_operator)
    self.operator_persistent_id = new_operator.persistent_id
    @operator = new_operator
  end

  def operator
    if @operator
      return @operator
    end
    if self.operator_persistent_id
      return Operator.current.find_by_persistent_id(self.operator_persistent_id)
    end
  end

  def location=(new_location)
    self.location_type = new_location.class.base_class.name.to_s
    self.location_persistent_id = new_location.persistent_id
    @location = new_location
  end

  def location
    if @location
      return @location
    end
    if self.location_type && self.location_persistent_id
      return self.location_type.constantize.current.find_by_persistent_id(self.location_persistent_id)
    end
    return nil
  end

  # at the moment operator contacts can only relate to stations
  def stop_area_persistent_id=(location_persistent_id)
    self.location_persistent_id = location_persistent_id
    self.location_type = 'StopArea'
  end

  def stop_area_persistent_id()
    self.location_persistent_id
  end

  def deleted_or_organization_deleted?
    (deleted? || operator.status == "DEL")
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
