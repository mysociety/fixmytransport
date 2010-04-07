require 'spec_helper'

describe Problem do
  before(:each) do
    @valid_attributes = {
      :subject => "value for subject",
      :description => "value for description"
    }
  end

  it "should create a new instance given valid attributes" do
    Problem.create!(@valid_attributes)
  end
end
