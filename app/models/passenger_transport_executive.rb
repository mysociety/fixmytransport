class PassengerTransportExecutive < ActiveRecord::Base
  has_many :areas, :class_name => "PassengerTransportExecutiveArea"
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  
  has_paper_trail
  
  def emailable? 
    !email.blank?
  end
    
end
