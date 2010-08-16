require 'spec_helper'

describe StopAreaOperator do
  before(:each) do
    @valid_attributes = {
      :stop_area_id => 1,
      :operator_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    StopAreaOperator.create!(@valid_attributes)
  end
end
