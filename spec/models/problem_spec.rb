require 'spec_helper'

describe Problem do
  
  describe 'when validating a reporter_name' do 
    
    before do 
      @problem = Problem.new()
      @problem.stub!(:location).and_return(mock('location'))
      @full_name_error = "Please enter your full name (if you do not wish your name to be shown on the site, untick the 'Can we show your name publicly' box)"
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
  
  describe 'when asked for a reply email' do 
    
    before do 
      @mock_reporter = mock_model(User)
      @problem = Problem.new()
      @problem.stub!(:reporter).and_return(@mock_reporter)
    end
    
    it 'should give the name and email address of the reporter if there is no associated campaign' do 
      @mock_reporter.should_receive(:name_and_email)
      @problem.reply_email
    end
    
    it 'should give the name and campaign email address of the reporter if there is an associated campaign' do 
      mock_campaign = mock_model(Campaign)
      @problem.stub!(:campaign).and_return(mock_campaign)
      @mock_reporter.should_receive(:campaign_name_and_email_address).with(mock_campaign)
      @problem.reply_email
    end
    
  end
  
  describe 'when creating assignments' do 
    
    before do 
      @problem = Problem.new
      @mock_user = mock_model(User)
      @problem.stub!(:reporter).and_return(@mock_user)
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
                              :problem => @problem  }
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
