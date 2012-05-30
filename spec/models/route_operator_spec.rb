# == Schema Information
# Schema version: 20100707152350
#
# Table name: route_operators
#
#  id          :integer         not null, primary key
#  operator_id :integer
#  route_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe RouteOperator do

  before(:each) do
    @mock_route = mock_model(Route)
    @mock_operator = mock_model(Operator)
    @mock_problem = mock_model(Problem)
    @valid_attributes = {
      :operator => @mock_operator,
      :route => @mock_route
    }
    @model_type = RouteOperator
    @operator = Operator.new
    @operator.stub!(:persistent_id).and_return(33)
    @route = Route.new
    @route.stub!(:persistent_id).and_return(22)
    @default_attrs = {
      :operator => @operator,
      :route => @route
    }
    @expected_identity_hash = { :operator => { :persistent_id => 33 },
                                :route => { :persistent_id => 22 } }
    @expected_external_identity_fields = [{:route=>[:number, {:region => [:code, :name]}]},
                                          {:operator=>[:noc_code, :name]}]
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"

  describe 'when creating a new route operator' do

    it "should create a new instance given valid attributes" do
      route_operator = RouteOperator.new(@valid_attributes)
      route_operator.valid?.should be_true
    end

  end

  after(:each) do
    RouteOperator.destroy_all
  end


end
