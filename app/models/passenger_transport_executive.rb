class PassengerTransportExecutive < ActiveRecord::Base
  has_many :areas, :class_name => "PassengerTransportExecutiveArea"
  has_paper_trail
  
  def emailable? 
    !email.blank?
  end
    
end
