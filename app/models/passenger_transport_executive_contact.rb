class PassengerTransportExecutiveContact < ActiveRecord::Base
  belongs_to :passenger_transport_executive
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  validates_presence_of :category
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  has_paper_trail
  
  def name
    passenger_transport_executive.name
  end
  
  def last_editor
    return nil if versions.empty? 
    return versions.last.whodunnit
  end
  
end