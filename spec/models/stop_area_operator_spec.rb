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
    
    it 'should raise an exception if problems exist with that stop area and operator' do 
      stop_area_operator = StopAreaOperator.new(@valid_attributes)
      conditions = ['location_type = ? AND location_id = ? AND operator_id = ?', 
                    'StopArea', stop_area_operator.stop_area.id, stop_area_operator.operator.id]
      Problem.should_receive(:find).with(:all, :conditions => conditions).and_return([@mock_problem])
      expected_error_message = "Cannot destroy association of stop area #{@mock_stop_area.id} with operator #{@mock_operator.id} - problems need updating"
      lambda{ stop_area_operator.check_problems() }.should raise_error(expected_error_message)
    end
    
  end
  
end
