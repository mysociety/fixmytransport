require 'spec_helper'

describe RouteLocality do
  before(:each) do
    @valid_attributes = {
      :locality_id => 1,
      :route_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    RouteLocality.create!(@valid_attributes)
  end
end
