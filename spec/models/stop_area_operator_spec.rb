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
    @expected_identity_hash_populated = true
  end

  it "should create a new instance given valid attributes" do
    stop_area_operator = StopAreaOperator.new(@valid_attributes)
    stop_area_operator.valid?.should be_true
  end

  it "should not be valid if an instance with its stop area and operator exists in the current data generation" do
    @current_generation_instance = StopAreaOperator.create!(@valid_attributes)
    instance = StopAreaOperator.new(@valid_attributes)
    instance.valid?.should == false
    instance.errors.full_messages.include?('Operator has already been taken').should be_true
  end

  it 'should be valid if its persistent id exists in a previous data generation' do
    previous_generation_attributes = { :generation_low => PREVIOUS_GENERATION,
                                       :generation_high => PREVIOUS_GENERATION }
    attributes = @valid_attributes.merge(previous_generation_attributes)
    @previous_generation_instance = StopAreaOperator.create!(attributes)
    instance = StopAreaOperator.new(@valid_attributes)
    instance.valid?.should == true
  end

  after do
    @current_generation_instance.destroy if @current_generation_instance
    @previous_generation_instance.destroy if @previous_generation_instance
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"

end
