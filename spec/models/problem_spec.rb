require 'spec_helper'

describe Problem do

  describe "when finding a location by attributes" do 
      
    before do 
      @problem = Problem.new(:transport_mode_id => 5)
      StopType.stub!(:codes_for_transport_mode).and_return([])
    end

    def expect_location(attributes, location_type, location)
      @problem.location_type = location_type
      @problem.location_attributes = attributes
      @problem.location_from_attributes
      @problem.locations.should == [location]
    end
  
    it 'should return nil if no location attributes have been set' do 
      @problem.location_attributes = nil
      @problem.location_from_attributes.should be_nil
    end
  
    it 'should ask for the stop type codes for the transport mode given' do 
      StopType.should_receive(:codes_for_transport_mode).with(5).and_return(['TES'])
      @problem.location_type = 'Stop'
      @problem.location_attributes = { :name => 'My stop', 
                                       :area => 'My town' }
      @problem.location_from_attributes                           
    end
  
    it 'should return a route if one is uniquely identified by the number and transport mode' do 
      route = mock_model(Route, :becomes => route)
      Route.stub!(:find_from_attributes).and_return([route])
      attributes = { :route_number => 'number' }
      expect_location(attributes, 'Route', route)
    end
  
    it 'should return a stop if one is uniquely identified by the attributes' do 
      stop = mock_model(Stop)
      Gazetteer.stub!(:find_stops_from_attributes).and_return({:results => [stop], :errors => []})
      attributes = { :name => 'name', :area => 'locality name' }
      expect_location(attributes, 'Stop',  stop)
    end
  
  end
  
  describe 'when creating an assignment' do 
    
    before do 
      @problem = Problem.new
      @mock_user = mock_model(User)
      @problem.stub!(:reporter).and_return(@mock_user)
      @mock_operator = mock_model(Operator, :email => "operator@example.com")
      @problem.stub!(:operator).and_return(@mock_operator)
    end
    
    def expect_assignment(name, status)
      Assignment.stub!(:create_assignment)
      expected_attributes = { :status => status, 
                              :task_type_name => name, 
                              :user => @mock_user, 
                              :problem => @problem }
      Assignment.should_receive(:create_assignment).with(expected_attributes)
    end
  
    describe 'when there are no assignments and the problem has an operator with an email address' do 
      
      it 'should create an in-progress assignment to write to the operator' do 
        expect_assignment('write-to-transport-operator', :in_progress)
        @problem.create_assignment
      end
      
      it 'should create an in-progress assignment to publish the problem on the site' do 
        expect_assignment('publish-problem', :in_progress)
        @problem.create_assignment
      end
    
    end
    
    describe 'when there are no assignments and the problem has an operator without an email address' do 
      
      before do 
        @mock_operator.stub!(:email).and_return(nil)
      end
      
      it 'should create an in-progress assignment to publish the problem on the site' do 
        expect_assignment("publish-problem", :in_progress)
        @problem.create_assignment        
      end
      
      it "should create a new assignment to find the operator's email address" do 
        expect_assignment("find-transport-operator-contact-details", :new)
        @problem.create_assignment
      end
      
    end
    
    describe 'when there are no assignments and the problem has no operator' do 
    
      before do 
        @problem.stub!(:operator).and_return(nil)
      end
      
      it 'should create an in-progress assignment to report the problem on the site' do 
        expect_assignment("publish-problem", :in_progress)
        @problem.create_assignment
      end
      
      it 'should create a new assignment to find out who the operator is' do 
        expect_assignment("find-transport-operator", :new)
        @problem.create_assignment
      end
      
      it "should create a new assignment to find the operator's email address" do 
        expect_assignment("find-transport-operator-contact-details", :new)
        @problem.create_assignment
      end
    
    end
    
  end

end
