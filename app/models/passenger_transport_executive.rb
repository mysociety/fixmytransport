class PassengerTransportExecutive < ActiveRecord::Base
  has_many :areas, :class_name => "PassengerTransportExecutiveArea"
  
  def emailable? 
    !email.blank?
  end
    
end
