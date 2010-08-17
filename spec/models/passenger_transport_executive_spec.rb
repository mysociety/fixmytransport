require 'spec_helper'

describe PassengerTransportExecutive do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :area_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    PassengerTransportExecutive.create!(@valid_attributes)
  end
end
