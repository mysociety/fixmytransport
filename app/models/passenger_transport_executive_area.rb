class PassengerTransportExecutiveArea < ActiveRecord::Base
  belongs_to :pte, :class_name => "PassengerTransportExecutive", :foreign_key => :passenger_transport_executive_id
  has_paper_trail
end
