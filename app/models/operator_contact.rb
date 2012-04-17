class OperatorContact < ActiveRecord::Base
  belongs_to :operator
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  validates_presence_of :category
  belongs_to :location, :polymorphic => true
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  validates_format_of :cc_email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$"), :allow_blank => true
  validate :category_unique_in_generation
  has_paper_trail

  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generation
  exists_in_data_generation()

  # this is a custom validation as categories need only be unique within the data generation bounds
  # set by the default scope. Allows blank values
  def category_unique_in_generation
    if !self.deleted
      self.field_unique_in_generation :category, :scope => [:operator_id,
                                                            :location_id,
                                                            :location_type,
                                                            :deleted]
    end
  end

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

end
