require 'spec_helper'

describe OperatorCode do
  before(:each) do
    @valid_attributes = {
      :region_id => 1,
      :operator_id => 1,
      :code => "value for code"
    }
    @model_type = OperatorCode
    @default_attrs = { :code => 'a test code' }
  end

  it "should create a new instance given valid attributes" do
    OperatorCode.create!(@valid_attributes)
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"
end
