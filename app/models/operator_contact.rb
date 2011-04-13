class OperatorContact < ActiveRecord::Base
  belongs_to :operator
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  validates_presence_of :category
  belongs_to :location, :polymorphic => true
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
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

end
