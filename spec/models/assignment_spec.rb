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
       task = Assignment.new( :status_code => 0 )
       task.status = :complete
       task.status_code.should == 1
     end

   end

   describe 'when asked for its status' do 

     it 'should return the correct symbol for its status code' do 
       task = Assignment.new( :status_code => 0 )
       task.status.should == :in_progress
       task.status_code = 1
       task.status.should == :complete
     end
   end

   describe 'when asked for its status description' do 

     it 'should return the correct description for its status code' do 
       task = Assignment.new( :status_code => 0 )
       task.status_description.should == 'In Progress'
       task.status_code = 1
       task.status_description.should == 'Complete'
     end

   end
   
    describe 'when creating an assignment from an attribute hash' do 
 
       before do
         # stub connection to Fosbury
         @mock_task = mock_model(Task, :save => true, 
                                       :id => 33)
         Task.stub!(:new).and_return(@mock_task)
         @mock_user = mock_model(User)
         @mock_assignment = mock_model(Assignment, :task_id= => true, 
                                                   :save => true, 
                                                   :id => 22)
         @attribute_hash = { :task_type_name => 'test-task-type-name', 
                             :user => @mock_user, 
                             :status => :complete, 
                             :data => { :problem_id => 44} }
       end
  
       it 'should create an assignment with the task type name, user and status values of the hash' do 
         Assignment.should_receive(:create).with(:task_type_name => 'test-task-type-name', 
                                                 :user => @mock_user, 
                                                 :status => :complete,
                                                 :data => { :problem_id => 44 }).and_return(@mock_assignment)
         Assignment.create_assignment(@attribute_hash)
       end
 
       it 'should create and save a task and set the task id on the assignment and the assignment id on the task' do 
         Assignment.stub!(:create).and_return(@mock_assignment)
         Task.should_receive(:new).with(:task_type_id => 'test-task-type-name', 
                                        :status => :complete, 
                                        :callback_params => {:assignment_id => 22}).and_return(@mock_task)
         @mock_assignment.should_receive(:task_id=).with(33)
         Assignment.create_assignment(@attribute_hash)
       end

    end
end
