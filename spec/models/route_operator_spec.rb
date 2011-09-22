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
  end
  
  describe 'when creating a new route operator' do

    it "should create a new instance given valid attributes" do
      route_operator = RouteOperator.new(@valid_attributes)
      route_operator.valid?.should be_true
    end
    
  end

end
