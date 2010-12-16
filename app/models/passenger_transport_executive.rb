class PassengerTransportExecutive < ActiveRecord::Base
  has_many :areas, :class_name => "PassengerTransportExecutiveArea"
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  
  has_paper_trail
  
  def emailable?(location)
    !email.blank?
  end
  
  def categories(location)
    ['Other']
  end
  
  def deleted? 
    false
  end
  
end
