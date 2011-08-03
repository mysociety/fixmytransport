require 'spec_helper'

describe SubRoute do
  before(:each) do
    @valid_attributes = {
      :from_station_id => 1,
      :to_station_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    sub_route = SubRoute.new(@valid_attributes)
    sub_route.valid?.should == true
  end
    
end
