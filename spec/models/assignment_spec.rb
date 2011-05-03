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
  
    
  describe 'when asked for unmet prerequisites' do 
    
    it 'should return true for a "write-to-transport-organization" assignment if there is an incomplete "find-transport-organization" assignment' do 
      incomplete_assignment = mock_model(Assignment, :task_type => 'find_transport_organization')
      mock_assignments = mock('assignments')
      mock_assignments.stub!(:incomplete).and_return([incomplete_assignment])
      mock_problem = mock_model(Problem, :assignments => mock_assignments)
      assignment = Assignment.new(:task_type_name => 'write-to-transport_organization')
      assignment.stub!(:problem).and_return(mock_problem)
      assignment.has_unmet_prerequisites?.should be_true
    end
    
    it 'should return false for a "write-to-transport-organization" assignment if there are no incomplete assignments' do 
      mock_assignments = mock('assignments')
      mock_assignments.stub!(:incomplete).and_return([])
      mock_problem = mock_model(Problem, :assignments => mock_assignments)
      assignment = Assignment.new(:task_type_name => 'write-to-transport_organization')
      assignment.stub!(:problem).and_return(mock_problem)
      assignment.has_unmet_prerequisites?.should be_false
    end
    
  end
   
  describe 'when completing' do 
    
    before do 
      @mock_problem = mock_model(Problem, :campaign => nil)
      @assignment = Assignment.new(:data => {},
                                   :problem => @mock_problem)
      @assignment.stub!(:save!).and_return(true)
    end
   
    it 'should update the data on the assignment' do
      @assignment.data.should_receive(:update).with(:x => :y)
      @assignment.complete!({ :x => :y })
    end

    it 'should set the status to complete' do
      @assignment.should_receive(:status=).with(:complete)
      @assignment.complete!
    end

    it 'should save the assignment' do
      @assignment.should_receive(:save!)
      @assignment.complete!
    end
   
    describe 'if the problem associated with the assignment has a campaign' do
    
      it 'should create an "assignment_completed" campaign event' do
        @mock_campaign = mock_model(Campaign, :campaign_events => [])
        @mock_problem.stub!(:campaign).and_return(@mock_campaign)
        @mock_campaign.campaign_events.should_receive(:create!).with(:event_type => 'assignment_completed', 
                                                                     :described => @assignment)
        @assignment.complete!
      end
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
                                                  :save! => true,
                                                  :data= => true, 
                                                  :data => {},
                                                  :complete! => nil)
        Assignment.stub!(:find).and_return(@mock_assignment)
      end
    
      it 'should find the assignment associated with the problem, problem reporter and task type name' do 
        expected_conditions = ["task_type_name = ? and problem_id = ? and user_id = ?", 
                               'write-to-transport-operator', @mock_problem.id, @mock_user.id]
        Assignment.should_receive(:find).with(:first, :conditions => expected_conditions)
        Assignment.complete_problem_assignments(@mock_problem, {'write-to-transport-operator' => {}})
      end
      
      it 'should complete the assignment' do
        @mock_assignment.should_receive(:complete!).with({})
        Assignment.complete_problem_assignments(@mock_problem, {'write-to-transport-operator' => {}})
      end
      
    end
    
    describe 'when validating assignments' do 

      def expect_validation_message(field, task_type_name, message)
        assignment = Assignment.new(:task_type_name => task_type_name)
        assignment.valid?.should be_false
        assignment.errors.on(field).should == message   
      end
      
      describe 'an assignment to write to someone about a problem' do 
    
        it 'should be invalid without a name to write to' do 
          expect_validation_message(:name, 'write-to-other', 'Please give the name of the person or organisation to write to')
        end
      
        it 'should be invalid without an email address to write to' do 
          expect_validation_message(:email, 'write-to-other', 'Please give the email address to write to')
        end
      
        it 'should be invalid without a reason to write to the person/organization' do 
          expect_validation_message(:reason, 'write-to-other', 'Please give a reason for writing to this person or organisation')
        end
      
        it 'should be invalid if the email address is not in the correct format' do 
          assignment = Assignment.new(:task_type_name => 'write-to-other', 
                                      :data => {:email => 'invalid_email'})
          assignment.valid?.should be_false
          assignment.errors.on(:email).should == 'Please check the format of the email address'   
        end

      end
    
      describe 'a new assignment to find a transport organization' do 
      
        it 'should be valid without an organization name to write to' do 
          assignment = Assignment.new(:task_type_name => 'find-transport-organization')
          assignment.valid?.should be_true          
        end
      
      end
      
      describe 'an existing assignment to find a transport organization' do 
      
        it 'should be invalid without an organization name to write to' do 
          assignment = Assignment.new(:task_type_name => 'find-transport-organization')
          assignment.stub!(:new_record?).and_return(false)
          assignment.valid?.should be_false  
          assignment.errors.on(:organization_name).should == 'Please give the company name'
        end
      end
      
      describe 'a new assignment to find contact details' do
         
        it 'should be valid without an organization email'  do 
          assignment = Assignment.new(:task_type_name => 'find-transport-organization-contact-details')
          assignment.valid?.should be_true          
        end
      
      end
      
      describe 'an existing assignment to find a transport organization' do 
        
        it 'should be invalid without an email' do 
          assignment = Assignment.new(:task_type_name => 'find-transport-organization-contact-details')
          assignment.stub!(:new_record?).and_return(false)
          assignment.valid?.should be_false  
          assignment.errors.on(:organization_email).should == "Please give the company's email address"
        end
      
        it 'should be invalid with an invalid email' do 
          assignment = Assignment.new(:task_type_name => 'find-transport-organization-contact-details')
          assignment.data = { :organization_email => 'bad email' }
          assignment.stub!(:new_record?).and_return(false)
          assignment.valid?.should be_false  
          assignment.errors.on(:organization_email).should == 'Please check the format of the email address'
        end
      
      end
    end
  
  describe 'when getting assignments that need attention' do 
  
    it 'should return in-progress assignments that are not "write-to-transport-organization" assignments' do 
      Assignment.should_receive(:find).with(:all, 
                                            :conditions => ['status_code = ? and task_type_name != ?', 
                                                          Assignment.symbol_to_status_code[:in_progress],
                                                          'write-to-transport-organization'], 
                                            :order => 'updated_at asc', 
                                            :limit => 10)
      Assignment.find_need_attention({:limit => 10})
    end
    
  end
end
