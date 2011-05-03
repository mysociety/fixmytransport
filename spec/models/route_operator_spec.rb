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
    
    it "should assign its operator to any unsent problems for this route that don't have an operator" do 
      conditions = ['location_type = ? AND location_id = ? AND operator_id is NULL', 'Route', @mock_route]
      Problem.stub!(:unsent).and_return([])
      Problem.unsent.should_receive(:find).with(:all, :conditions => conditions).and_return([@mock_problem])
      @mock_problem.should_receive(:operator=).with(@mock_operator)
      @mock_problem.should_receive(:save!)
      route_operator = RouteOperator.new(@valid_attributes)
      route_operator.update_problems()
    end
    
  end

  describe 'when destroying a route operator' do 
    
    it 'should raise an exception if problems exist with that route and operator' do 
      route_operator = RouteOperator.new(@valid_attributes)
      conditions = ['location_type = ? AND location_id = ? AND operator_id = ?', 
                    'Route', route_operator.route.id, route_operator.operator.id]
      Problem.should_receive(:find).with(:all, :conditions => conditions).and_return([@mock_problem])
      expected_error_message = "Cannot destroy association of route #{@mock_route.id} with operator #{@mock_operator.id} - problems need updating"
      lambda{ route_operator.check_problems() }.should raise_error(expected_error_message)
    end
    
  end
end
