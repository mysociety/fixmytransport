require 'spec_helper'

describe OperatorCode do

  before(:each) do
    @valid_attributes = {
      :region_id => 1,
      :operator_id => 1,
      :code => "value for code"
    }
    @model_type = OperatorCode
    @region = Region.new(:code => 'xxx', :name => 'A test region')
    @region.stub!(:persistent_id).and_return(88)
    @operator = Operator.new(:noc_code => 'xxxx', :name => 'A test operator')
    @operator.stub!(:persistent_id).and_return(66)
    @default_attrs = { :code => 'a test code', :operator => @operator, :region => @region }
    @expected_identity_hash = { :code => 'a test code',
                                :region =>  { :persistent_id => 88 },
                                :operator => { :persistent_id => 66 }}
    @expected_external_identity_fields = [:code,
                                          {:region => [:code, :name]},
                                          {:operator => [:noc_code, :name]}]
    @expected_identity_hash_populated = true
  end

  it "should create a new instance given valid attributes" do
    OperatorCode.create!(@valid_attributes)
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"

end
