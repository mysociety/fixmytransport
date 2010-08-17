require 'spec_helper'

describe PassengerTransportExecutiveAreas do
  before(:each) do
    @valid_attributes = {
      :area_id => 1,
      :passenger_transport_executive => 1
    }
  end

  it "should create a new instance given valid attributes" do
    PassengerTransportExecutiveAreas.create!(@valid_attributes)
  end
end
