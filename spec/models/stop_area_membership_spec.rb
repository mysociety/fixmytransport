require 'spec_helper'

describe StopAreaMembership do
  before(:each) do
    @valid_attributes = {
      :stop_id => 1,
      :stop_area_id => 1,
      :creation_datetime => Time.now,
      :modification_datetime => Time.now,
      :revision_number => 1,
      :modification => "value for modification"
    }
  end

  it "should create a new instance given valid attributes" do
    membership = StopAreaMembership.new(@valid_attributes)
    membership.valid?.should be_true
  end
end
