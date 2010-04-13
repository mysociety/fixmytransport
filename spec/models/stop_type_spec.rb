require 'spec_helper'

describe StopType do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :description => "value for description",
      :on_street => false,
      :mode => "value for mode",
      :point_type => "value for point_type",
      :version => 1.5
    }
  end

  it "should create a new instance given valid attributes" do
    StopType.create!(@valid_attributes)
  end
end
