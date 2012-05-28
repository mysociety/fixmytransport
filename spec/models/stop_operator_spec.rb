require 'spec_helper'

describe StopOperator do

  fixtures :stops, :operators

  before(:each) do
    @mock_stop = mock_model(Stop)
    @mock_operator = mock_model(Operator)

    @valid_attributes = {
      :stop => @mock_stop,
      :operator => @mock_operator
    }
    @operator = operators(:a_train_company)
    @stop = stops(:victoria_station_one)

    @default_attrs = {
      :stop_id => @stop.id,
      :operator_id => @operator.id
    }

    @model_type = StopOperator
    @expected_identity_hash = {}
  end

  it "should create a new instance given valid attributes" do
    stop_operator = StopOperator.new(@valid_attributes)
    stop_operator.valid?.should be_true
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"

  after(:each) do
    StopOperator.destroy_all
  end

end