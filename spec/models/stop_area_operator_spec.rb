require 'spec_helper'

describe StopAreaOperator do

  before(:each) do
    @valid_attributes = {
      :stop_area_id => 1,
      :operator_id => 1
    }

    @stop_area = StopArea.new
    @stop_area.stub!(:persistent_id).and_return(66)
    @operator = Operator.new
    @operator.stub!(:persistent_id).and_return(44)
    @default_attrs = {
      :stop_area => @stop_area,
      :operator => @operator
    }
    @model_type = StopAreaOperator
    @expected_identity_hash = { :stop_area => { :persistent_id => 66 },
                                :operator => { :persistent_id => 44 } }
    @expected_external_identity_fields = [{:stop_area => [:code, :name]},
                                          {:operator => [:noc_code, :name]}]
  end

  it "should create a new instance given valid attributes" do
    StopAreaOperator.create!(@valid_attributes)
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"

end
