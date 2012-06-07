require 'spec_helper'

describe StopOperator do


  before(:each) do
    @mock_stop = mock_model(Stop)
    @mock_operator = mock_model(Operator)

    @valid_attributes = {
      :stop => @mock_stop,
      :operator => @mock_operator
    }
    @operator = Operator.new
    @operator.stub!(:persistent_id).and_return(44)
    @stop = Stop.new
    @stop.stub!(:persistent_id).and_return(88)
    @default_attrs = {
      :stop => @stop,
      :operator => @operator
    }
    @model_type = StopOperator
    @expected_identity_hash = {:stop => {:persistent_id => 88},
                               :operator => {:persistent_id => 44}}
    @expected_external_identity_fields = [{:stop=>[:atco_code, :name]}, {:operator=>[:noc_code, :name]}]
    @expected_identity_hash_populated = true
  end

  it "should create a new instance given valid attributes" do
    stop_operator = StopOperator.new(@valid_attributes)
    stop_operator.valid?.should be_true
  end

  after do
    @current_generation_instance.destroy if @current_generation_instance
    @previous_generation_instance.destroy if @previous_generation_instance
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"

end