class PassengerTransportExecutiveContact < ActiveRecord::Base

  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  validates_presence_of :category
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  validates_format_of :cc_email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$"), :allow_blank => true
  validates_uniqueness_of :category, :scope => [:passenger_transport_executive_persistent_id,
                                                :location_type,
                                                :deleted],
                                     :if => Proc.new { |contact| ! contact.deleted? }
  has_paper_trail

  def name
    passenger_transport_executive.name
  end

  def last_editor
    return nil if versions.empty?
    return versions.last.whodunnit
  end

  def passenger_transport_executive=(new_passenger_transport_executive)
    self.passenger_transport_executive_persistent_id = new_passenger_transport_executive.persistent_id
    @passenger_transport_executive = new_passenger_transport_executive
  end

  def passenger_transport_executive
    if @passenger_transport_executive
      return @passenger_transport_executive
    end
    if self.passenger_transport_executive_persistent_id
      return PassengerTransportExecutive.current.find_by_persistent_id(self.passenger_transport_executive_persistent_id)
    end
  end

  def deleted_or_organization_deleted?
    (deleted? || passenger_transport_executive.status == "DEL")
  end

end