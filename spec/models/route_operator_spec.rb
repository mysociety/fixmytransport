require 'spec_helper'

describe RouteOperator do
  before(:each) do
    @valid_attributes = {
      :operator_id => 1,
      :route_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    route_operator = RouteOperator.new(@valid_attributes)
    route_operator.valid?.should be_true
  end
end
