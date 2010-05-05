require 'spec_helper'

describe LocationSearch do
  before(:each) do
    @valid_attributes = {
      :transport_mode_id => 1,
      :name => "value for name",
      :area => "value for area",
      :route_number => "value for route_number",
      :location_type => "value for location_type"
    }
  end

  it "should create a new instance given valid attributes" do
    LocationSearch.create!(@valid_attributes)
  end


end
