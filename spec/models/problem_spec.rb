require 'spec_helper'

describe Problem do

  describe 'when asked if it is visible' do

    it 'should return true if the status is confirmed' do
      @problem = Problem.new
      @problem.status = :confirmed
      @problem.visible?.should == true
    end

    it 'should return false if the status is new' do
      @problem = Problem.new
      @problem.status = :new
      @problem.visible?.should == false
    end

  end

  describe 'when creating a problem from a hash' do 
    
    
    before do
      @problem_data = { :subject => 'test subject',
                        :description => 'test description',
                        :category => 'Other',
                        :location_id => 55,
                        :location_type => 'Route',
                        :responsibilities => '22|Council' }
      @user = mock_model(User, :name => 'Test User')
      @expected_params = { :subject => 'test subject',
                           :description => 'test description',
                           :category => 'Other',
                           :location_id => 55,
                           :location_type => 'Route' }
      @mock_problem = mock_model(Problem, :responsibilities => mock('responsibilities', :build => nil),
                                          :status= => nil,
                                          :save! => true,
                                          :reporter= => true)
    end
  
    it 'should create responsibilities from a comma and pipe delimited string keyed by "responsibilities"' do 
      Problem.stub!(:new).and_return(@mock_problem)
      @mock_problem.responsibilities.should_receive(:build).with(:organization_id => "22",
                                                                :organization_type => 'Council')
      @mock_problem.responsibilities.should_receive(:build).with(:organization_id => "55", 
                                                                :organization_type => 'Council')
      problem_hash = { :subject => 'A Test Subject', 
                       :description => 'A Test Description', 
                       :location_id => 55, 
                       :location_type => 'Route', 
                       :category => 'Other', 
                       :responsibilities => '22|Council,55|Council' }
      p = Problem.create_from_hash(problem_hash, @user)
    end

    it 'should build a problem with the params passed' do
      Problem.should_receive(:new).with(@expected_params).and_return(@mock_problem)
      Problem.create_from_hash(@problem_data, @user)
    end

    describe 'if the data has a key :text_encoded set to true' do

      it 'should base64 decode the description field before building the problem' do
        @problem_data[:text_encoded] = true
        @problem_data[:description] = ActiveSupport::Base64.encode64(@problem_data[:description])
        Problem.should_receive(:new).with(@expected_params).and_return(@mock_problem)
        Problem.create_from_hash(@problem_data, @user)
      end

    end

  end

  describe 'when updating assignments' do 
    
    describe 'if the problem has no responsible organizations' do 
      
      before do
        @problem = Problem.new
        @problem.stub!(:responsible_organizations).and_return([])
      end
    
      it 'should return true' do 
        @problem.update_assignments().should == true
      end
    
    end
  
  
  end

  describe 'when asked for recipient emails' do

    before do
      MySociety::Config.stub!(:get).with('CONTACT_EMAIL', 'contact@localhost').and_return('contact@example.com')
      @problem = Problem.new
    end

    it 'should return the a hash with the :to key set to the site contact address for a staging site' do
      MySociety::Config.stub!(:getbool).with('STAGING_SITE', true).and_return(true)
      @problem.recipient_emails(mock_model(Operator)).should == { :to => 'contact@example.com' }
    end

    describe 'when the site is not a staging site' do

      before do
        MySociety::Config.stub!(:getbool).with('STAGING_SITE', true).and_return(false)
        @operator_contact = mock_model(OperatorContact, :email => 'operator@example.com')
        @operator = mock_model(Operator)
        @problem.stub!(:recipient_contact).and_return(@operator_contact)
      end

      it 'should return the site contact address for a route with number "ZZ9"' do
        @problem.stub!(:location).and_return(Route.new(:number => 'ZZ9'))
        @problem.recipient_emails(@operator).should == { :to => 'contact@example.com' }
      end

      it 'should ask for the recipient contact for a recipient' do
        @problem.should_receive(:recipient_contact).with(@operator).and_return(@operator_contact)
        @problem.recipient_emails(@operator)
      end

      it 'should return a hash with key :to set to the email of the recipient contact' do
        @problem.recipient_emails(@operator)[:to].should == 'operator@example.com'
      end

      describe 'if the contact has a cc_email method' do

        before do
          @operator_contact.stub!(:cc_email).and_return('cc@example.com')
        end

        it 'should return a hash with key :cc set to the cc of the recipient contact' do
          @problem.recipient_emails(@operator)[:cc].should == 'cc@example.com'
        end
      end

    end

  end

  describe 'when asked for a recipient contact' do

    before do
      @stop = Stop.new
      @problem = Problem.new()
      @problem.location = @stop
      @problem.stub!(:category).and_return('Other')
    end

    it 'should raise an error if asked for a contact for something other than a council, PTE or operator' do
      lambda{ @problem.recipient_contact(User.new) }.should raise_error('Unknown recipient type: User')
    end

    it 'should ask an operator for its contact for a category and location' do
      operator = mock_model(Operator)
      operator.should_receive(:contact_for_category_and_location).with('Other', @stop)
      @problem.recipient_contact(operator)
    end

  end

  describe 'when asked for recipients' do

    it 'should not include recipients of comment emails' do
      problem = Problem.new
      user = mock_model(User)
      operator = mock_model(Operator)
      comment_sent_email = mock_model(SentEmail, :problem => problem,
                                                 :comment_id => 22,
                                                 :recipient => user)
      problem_report_sent_email = mock_model(SentEmail, :problem => problem,
                                                        :comment_id => nil,
                                                        :recipient => operator)
      problem.stub!(:sent_emails).and_return([comment_sent_email, problem_report_sent_email])
      problem.recipients.should == [operator]
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
      @problem.stub!(:add_coords)
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

      it 'should create a confirmed subscription for the problem reporter' do
        time_now = Time.now
        Time.stub!(:now).and_return(time_now)

        Subscription.should_receive(:create!).with(:user => @problem.reporter,
                                                   :target => @problem,
                                                   :confirmed_at => time_now)
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
      mock_campaign.should_receive(:email_address)
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
