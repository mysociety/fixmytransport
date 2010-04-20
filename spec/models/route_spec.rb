require 'spec_helper'

describe Route do
  before(:each) do
    @valid_attributes = {
      :transport_mode_id => 1,
      :number => "value for number"
    }
  end

  it "should create a new instance given valid attributes" do
    Route.create!(@valid_attributes)
  end
end
