require 'spec_helper'

describe TransportModeStopType do
  before(:each) do
    @valid_attributes = {
      :transport_mode_id => 1,
      :stop_type_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    transport_mode_stop_type = TransportModeStopType.new(@valid_attributes)
    transport_mode_stop_type.valid?.should be_true
  end
end
