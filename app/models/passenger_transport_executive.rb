class PassengerTransportExecutive < ActiveRecord::Base
  has_many :areas, :class_name => "PassengerTransportExecutiveArea"
end
