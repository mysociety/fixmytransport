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

  fixtures :routes, :operators

  before(:each) do
    @mock_route = mock_model(Route)
    @mock_operator = mock_model(Operator)
    @mock_problem = mock_model(Problem)
    @valid_attributes = {
      :operator => @mock_operator,
      :route => @mock_route
    }
    @model_type = RouteOperator
    @operator = operators(:a_train_company)
    @route = routes(:victoria_to_haywards_heath)
    @default_attrs = {
      :operator_id => @operator.id,
      :route_id => @route.id
    }
    @expected_identity_hash = { :operator_id => @mock_operator.id, :route_id => @mock_route.id }
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
