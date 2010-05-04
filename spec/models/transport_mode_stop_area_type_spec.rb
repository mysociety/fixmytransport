require 'spec_helper'

describe TransportModeStopAreaType do
  before(:each) do
    @valid_attributes = {
      :transport_mode_id => 1,
      :stop_area_type_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    TransportModeStopAreaType.create!(@valid_attributes)
  end
end
