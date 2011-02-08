require 'spec_helper'

describe Assignment do
  before(:each) do
    @valid_attributes = {
      :user_id => 1,
      :campaign_id => 1,
      :task_id => 1,
      :status_code => 0,
      :data => "value for data"
    }
  end

  it "should create a new instance given valid attributes" do
    Assignment.create!(@valid_attributes)
  end
  
  describe 'when accepting a status update' do 

     it "should update its status code" do 
       assignment = Assignment.new
       assignment.status_code = 1 
       assignment.status = :complete
       assignment.status_code.should == 2
     end

   end

   describe 'when asked for its status' do 

     it 'should return the correct symbol for its status code' do 
       assignment = Assignment.new
       assignment.status_code = 1
       assignment.status.should == :in_progress
       assignment.status_code = 2
       assignment.status.should == :complete
     end
   end

   describe 'when asked for its status description' do 

     it 'should return the correct description for its status code' do 
       assignment = Assignment.new
       assignment.status_code = 1
       assignment.status_description.should == 'In Progress'
       assignment.status_code = 2
       assignment.status_description.should == 'Complete'
     end

   end
   
    describe 'when creating an assignment from an attribute hash' do 
 
       before do
         @mock_user = mock_model(User)
         @mock_assignment = mock_model(Assignment, :task_id= => true, 
                                                   :save! => true, 
                                                   :id => 22,
                                                   :data= => true)
         @mock_problem = mock_model(Problem) 
         @attribute_hash = { :task_type_name => 'test-task-type-name', 
                             :user => @mock_user, 
                             :status => :complete, 
                             :problem => @mock_problem,
                             :data => {}}
       end
  
       it 'should create an assignment with the task type name, user and status values of the hash' do 
         Assignment.should_receive(:new).with(:task_type_name => 'test-task-type-name', 
                                                 :user => @mock_user, 
                                                 :data => {},
                                                 :problem => @mock_problem).and_return(@mock_assignment)
         @mock_assignment.should_receive(:status=).with(:complete)
         @mock_assignment.should_receive(:save!)
         Assignment.create_assignment(@attribute_hash)
       end


    end
    
    describe "when completing problem assignments" do 
      
      before do 
        @mock_user = mock_model(User, :id => 44)
        @mock_problem = mock_model(Problem, :reporter => @mock_user)
        @mock_assignment = mock_model(Assignment, :status= => true, 
                                                  :save => true, 
                                                  :data= => true, 
                                                  :data => {})
        Assignment.stub!(:find).and_return(@mock_assignment)
      end
    
      it 'should find the assignment associated with the problem, problem reporter and task type name' do 
        expected_conditions = ["task_type_name = ? and problem_id = ? and user_id = ?", 
                               'write-to-transport-operator', @mock_problem.id, @mock_user.id]
        Assignment.should_receive(:find).with(:first, :conditions => expected_conditions)
        Assignment.complete_problem_assignments(@mock_problem, {'write-to-transport-operator' => {}})
      end
      
      it 'should mark the assignment as complete' do 
        @mock_assignment.should_receive(:status=).with(:complete)
        Assignment.complete_problem_assignments(@mock_problem, {'write-to-transport-operator' => {}})
      end
      
      it 'should save the assignment' do 
        @mock_assignment.should_receive(:save)
        Assignment.complete_problem_assignments(@mock_problem, {'write-to-transport-operator' => {}})
      end
      
      it 'should update the data on the assignment' do
         @mock_assignment.data.should_receive(:update).with(:x => :y)
         Assignment.complete_problem_assignments(@mock_problem, {'write-to-transport-operator' => { :x => :y } })
       end
      
    end
    
    describe 'an assignment to write to someone about a problem' do 
    
      def expect_validation_message(field, message)
        assignment = Assignment.new(:task_type_name => 'write-to-other')
        assignment.valid?.should be_false
        assignment.errors.on(field).should == message   
      end
      
      it 'should be invalid without a name to write to' do 
        expect_validation_message(:name, 'Please give the name of the person or organisation to write to')
      end
      
      it 'should be invalid without an email address to write to' do 
        expect_validation_message(:email, 'Please give the email address to write to')
      end
      
      it 'should be invalid without a reason to write to the person/organization' do 
        expect_validation_message(:reason, 'Please give a reason for writing to this person or organisation')
      end
      
      it 'should be invalid if the email address is not in the correct format' do 
        assignment = Assignment.new(:task_type_name => 'write-to-other', 
                                    :data => {:email => 'invalid_email'})
        assignment.valid?.should be_false
        assignment.errors.on(:email).should == 'Please check the format of the email address'   
      end

    end

end
