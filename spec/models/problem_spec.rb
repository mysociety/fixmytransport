require 'spec_helper'

describe Problem do
  
  describe 'when validating a reporter_name' do 
    
    before do 
      @problem = Problem.new()
      @problem.stub!(:location).and_return(mock('location'))
      @full_name_error = "Please enter your full name"
    end
    
    it 'should add an error if the name is some variant of "anon"' do 
      ['anon', 'anonymous', 'anonymos', 'anonymously'].each do |anon_variant|
        @problem.errors.clear
        @problem.reporter_name = anon_variant
        @problem.validate_reporter_name
        @problem.errors.on(:reporter_name).should == @full_name_error
      end
    end
    
    it 'should add an error if the name is less than 5 characters' do 
      @problem.reporter_name = 'A B'
      @problem.valid?
      @problem.errors.on(:reporter_name).should == @full_name_error
    end
    
    it 'should add an error if the name does not have a non space, followed by a space, followed by a non space' do 
      ['Firstname ', ' Lastname'].each do |no_space|
        @problem.errors.clear
        @problem.reporter_name = no_space
        @problem.validate_reporter_name
        @problem.errors.on(:reporter_name).should == @full_name_error
      end
    end
    
  end
  
  describe 'when confirming' do 
    
    before do
      @problem = Problem.new
      @problem.status = :new
      @confirmation_time = Time.now - 5.days
      @problem.confirmed_at = @confirmation_time
      @problem.stub!(:save!).and_return(true)
      @problem.stub!(:organization_info).and_return([])
      @problem.stub!(:emailable_organizations).and_return([])
      @problem.stub!(:create_assignments)
      Assignment.stub!(:complete_problem_assignments)
    end
    
    describe 'when the status is not new' do 
      
      before do 
        @problem.status = :hidden
      end
      
      it 'should not change the status or set the confirmed time' do 
        @problem.confirm!
        @problem.status.should == :hidden
        @problem.confirmed_at.should == @confirmation_time
      end
    
    end
    
    describe 'when the status is new' do 
      
      it 'should set the status to confirmed and set the confirmed time on the problem' do 
        @problem.confirm!
        @problem.status.should == :confirmed
        @problem.confirmed_at.should > @confirmation_time
      end
      
      it 'should create assignments associated with the problem' do 
        @problem.should_receive(:create_assignments)
        @problem.confirm!
      end

      it 'should set the "publish-problem" assignments associated with this user and problem as complete' do 
        assignment_data =  { 'publish-problem' => {} }
        Assignment.should_receive(:complete_problem_assignments).with(@problem, assignment_data)
        @problem.confirm!
      end
      
      describe 'if the problem has emailable organizations' do
    
        before do 
          @problem.stub!(:emailable_organizations).and_return(['some'])
        end
        
        it 'should set the "write-to-transport-organization" assignment associated with this user and problem as complete' do 
          @problem.stub!(:responsible_organizations).and_return([mock_model(Operator)])
          @problem.stub!(:organization_info).and_return({ :data => 'data' })
          assignment_data = { 'write-to-transport-organization' => { :organizations => {:data => 'data'} } }
          Assignment.should_receive(:complete_problem_assignments).with(@problem, assignment_data)
          @problem.confirm!
        end
    
      end
      
      it 'should not set the "write-to-transport-organization" assignment associated with this user and problem as complete if there are no emailable organizations' do 
        @problem.stub!(:emailable_organizations).and_return([])
        @problem.stub!(:organization_info).and_return({ :data => 'data' })
        assignment_data ={ 'write-to-transport-organization' => { :data => 'data' } }
        Assignment.should_not_receive(:complete_problem_assignments).with(@problem, hash_including({'write-to-transport-organization'=> { :data => 'data' } }))
        @problem.confirm!
      end
    
    end
  
  end
  
  describe 'when asked for a reply name and email or reply email' do 
    
    before do 
      @mock_reporter = mock_model(User)
      @problem = Problem.new()
      @problem.stub!(:reporter).and_return(@mock_reporter)
    end
    
    it 'should give the name and email address of the reporter if there is no associated campaign' do 
      @mock_reporter.should_receive(:name_and_email)
      @problem.reply_name_and_email
    end
    
    it 'should give the email address of the reporter if there is no associated campaign' do
      @mock_reporter.should_receive(:email)
      @problem.reply_email
    end
    
    it 'should give the name and campaign email address of the reporter if there is an associated campaign' do 
      mock_campaign = mock_model(Campaign)
      @problem.stub!(:campaign).and_return(mock_campaign)
      @mock_reporter.should_receive(:campaign_name_and_email_address).with(mock_campaign)
      @problem.reply_name_and_email
    end
    
    it 'should give the campaign email address of the reporter if there is an associated campaign' do 
      mock_campaign = mock_model(Campaign)
      @problem.stub!(:campaign).and_return(mock_campaign)
      @mock_reporter.should_receive(:campaign_email_address).with(mock_campaign)
      @problem.reply_email
    end
    
  end
  
  describe 'when creating assignments' do 
    
    before do 
      @problem = Problem.new
      @mock_user = mock_model(User)
      @mock_campaign = mock_model(Campaign)
      @problem.stub!(:reporter).and_return(@mock_user)
      @problem.stub!(:campaign).and_return(@mock_campaign)
      @mock_operator = mock_model(Operator, :name => 'emailable operator')
      @problem.stub!(:responsible_organizations).and_return([@mock_operator])
      @problem.stub!(:emailable_organizations).and_return([@mock_operator])
      @problem.stub!(:unemailable_organizations).and_return([])
    end
    
    def expect_assignment(name, status)
      Assignment.stub!(:create_assignment)
      expected_attributes = { :status => status, 
                              :task_type_name => name, 
                              :user => @mock_user, 
                              :problem => @problem,
                              :campaign => @mock_campaign }
      Assignment.should_receive(:create_assignment).with(hash_including(expected_attributes))
    end
  
    describe 'when there are no assignments and the problem has a responsible org. with an email address' do 
      
      it 'should create an in-progress assignment to write to the operator' do 
        expect_assignment('write-to-transport-organization', :in_progress)
        @problem.create_assignments
      end
      
      it 'should create an in-progress assignment to publish the problem on the site' do 
        expect_assignment('publish-problem', :in_progress)
        @problem.create_assignments
      end
    
    end
    
    describe 'when there are no assignments and the problem has a responsible org. without an email address' do 
      
      before do 
        @problem.stub!(:unemailable_organizations).and_return([@mock_operator])
      end
      
      it 'should create an in-progress assignment to publish the problem on the site' do 
        expect_assignment("publish-problem", :in_progress)
        @problem.create_assignments        
      end
      
      it "should create a new assignment to find the organization's email address" do 
        expect_assignment("find-transport-organization-contact-details", :new)
        @problem.create_assignments
      end
      
    end
    
    describe 'when there are no assignments and the problem has no responsible orgs.' do 
    
      before do 
        @problem.stub!(:responsible_organizations).and_return([])
      end
      
      it 'should create an in-progress assignment to report the problem on the site' do 
        expect_assignment("publish-problem", :in_progress)
        @problem.create_assignments
      end
      
      it 'should create a new assignment to find out who the responsible organization is' do 
        expect_assignment("find-transport-organization", :new)
        @problem.create_assignments
      end
    
    end
    
  end

end
