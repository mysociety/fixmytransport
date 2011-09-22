require 'spec_helper'

describe StopAreaOperator do
  before(:each) do
    @valid_attributes = {
      :stop_area_id => 1,
      :operator_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    StopAreaOperator.create!(@valid_attributes)
  end
  
  describe 'when destroying a stop area operator' do 
    
    before do
      @mock_stop_area = mock_model(StopArea)
      @mock_operator = mock_model(Operator)
      @mock_problem = mock_model(Problem)
      @valid_attributes = {
        :operator => @mock_operator,
        :stop_area => @mock_stop_area
      }
    end

  end
  
end
