require 'spec_helper'

describe StopAreaOperator do
  before(:each) do
    @valid_attributes = {
      :stop_area_id => 1,
      :operator_id => 1
    }
    @default_attrs = {
      :stop_area_id => 1,
      :operator_id => 1
    }
    @model_type = StopAreaOperator
    @expected_identity_hash = { :stop_area_id => 1, :operator_id => 1 }
  end

  it "should create a new instance given valid attributes" do
    StopAreaOperator.create!(@valid_attributes)
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"


end
