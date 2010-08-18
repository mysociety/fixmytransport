require 'spec_helper'

describe PassengerTransportExecutiveArea do
  before(:each) do
    @valid_attributes = {
      :area_id => 1,
      :passenger_transport_executive_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    PassengerTransportExecutiveArea.create!(@valid_attributes)
  end
end
