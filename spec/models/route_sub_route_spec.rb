require 'spec_helper'

describe RouteSubRoute do
  before(:each) do
    @valid_attributes = {
      :route_id => 1,
      :sub_route_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    RouteSubRoute.create!(@valid_attributes)
  end
end
