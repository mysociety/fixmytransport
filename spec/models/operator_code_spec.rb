require 'spec_helper'

describe OperatorCode do
  before(:each) do
    @valid_attributes = {
      :region_id => 1,
      :operator_id => 1,
      :code => "value for code"
    }
  end

  it "should create a new instance given valid attributes" do
    OperatorCode.create!(@valid_attributes)
  end
end
