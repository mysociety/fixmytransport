require 'spec_helper'

describe StopAreaType do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :description => "value for description"
    }
  end

  it "should create a new instance given valid attributes" do
    StopAreaType.create!(@valid_attributes)
  end
end
