require 'spec_helper'

describe SubRoute do
  before(:each) do
    @valid_attributes = {
      :from_station_id => 1,
      :to_station_id => 1,
      :departure_time => "value for departure_time"
    }
  end

  it "should create a new instance given valid attributes" do
    SubRoute.create!(@valid_attributes)
  end
end
