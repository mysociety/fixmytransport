require 'spec_helper'

describe AssignmentsController do

  shared_examples_for "an action requiring an expert" do

    describe 'and the current user is not an expert' do

      before do
        mock_user = mock_model(User, :is_expert? => false)
        controller.stub!(:current_user).and_return(mock_user)
      end

      it 'should render the "wrong_user" template' do
        make_request
        response.should render_template('shared/wrong_user')
      end

      it 'should assign variables for an appropriate message' do
        make_request
        assigns[:name].should == 'a FixMyTransport boffin'
        assigns[:access_message].should == @expected_access_message
      end

    end

    describe 'and there is no current user' do

      it 'should redirect to the login page with a message' do
        controller.stub!(:current_user).and_return(nil)
        make_request
        response.should redirect_to(login_url)
        flash[:notice].should == "Login as a FixMyTransport boffin to create an assignment for this campaign"
      end

    end

  end

  describe 'GET #new' do

    before do
      @expert_user = mock_model(User, :is_expert? => true,
                                      :name => 'Ken Expert')
      @initiator = mock_model(User, :name => 'Joe Bloggs',
                                    :first_name => 'Joe')
      mock_assignments = mock('assignments', :build => true)
      @campaign = mock_model(Campaign, :visible? => true,
                                       :editable? => true,
                                       :initiator => @initiator,
                                       :assignments => mock_assignments)
      Campaign.stub!(:find).and_return(@campaign)
      @expected_access_message = :assignments_new_access_message
    end

    def make_request
      get :new, :campaign_id => 44
    end

    it_should_behave_like "an action requiring a visible campaign"
    it_should_behave_like "an action requiring an expert"

    describe 'if the current user is an expert' do

      before do
        controller.stub!(:current_user).and_return(@expert_user)
      end

      it 'should render the new template' do
        make_request
        response.should render_template("new")
      end

    end

  end

  describe 'POST #create' do

    before do
      @expert_user = mock_model(User, :is_expert? => true)
      @initiator = mock_model(User, :name => 'Joe Bloggs')
      @campaign_events_mock = mock('campaign events association', :create! => nil)
      @campaign = mock_model(Campaign, :visible? => true,
                                       :editable? => true,
                                       :initiator => @initiator,
                                       :problem => mock_model(Problem),
                                       :campaign_events => @campaign_events_mock)
      Campaign.stub!(:find).and_return(@campaign)
      @expected_access_message = :assignments_create_access_message
      @assignment = mock_model(Assignment, :save => true, :user => @initiator)
      Assignment.stub!(:assignment_from_attributes).and_return(@assignment)
      CampaignMailer.stub!(:deliver_write_to_other_assignment)
    end

    def make_request
      post :create, { :campaign_id => 44,
                      :name => 'A name',
                      :email => 'An email',
                      :reason => 'A reason',
                      :subject => 'subject',
                      :draft_text => 'Some draft text' }
    end

    it_should_behave_like "an action requiring a visible campaign"
    it_should_behave_like "an action requiring an expert"


    describe 'if the current user is an expert' do

      before do
        controller.stub!(:current_user).and_return(@expert_user)
      end

      it 'should create an assignment from the attributes passed' do
        expected_data = { :name => 'A name',
                          :email => 'An email',
                          :reason => 'A reason',
                          :subject => 'subject',
                          :draft_text => 'Some draft text' }
        Assignment.should_receive(:assignment_from_attributes).with(:campaign => @campaign,
                                                                    :data => expected_data,
                                                                    :problem => @campaign.problem,
                                                                    :status => :new,
                                                                    :creator => @expert_user,
                                                                    :task_type_name => 'write-to-other',
                                                                    :user => @campaign.initiator)
        make_request
      end

      it 'should try to save the assignment' do
        @assignment.should_receive(:save)
        make_request
      end

      describe 'if the assignment can be saved' do

        before do
          @assignment.stub!(:save).and_return(true)
        end

        it 'should send an email to the assignment user telling them about the assignment' do
          CampaignMailer.should_receive(:deliver_write_to_other_assignment)
          make_request
        end

        it 'should redirect to the campaign page' do
          make_request
          response.should redirect_to(campaign_path(@campaign))
        end

        it 'should show a notice saying that the user has been notified' do
          make_request
          flash[:notice].should == "Thanks! We've sent your advice to Joe Bloggs"
        end

        it 'should add an "assignment_given" event to the campaign' do
          @campaign_events_mock.should_receive(:create!).with({ :event_type => 'assignment_given',
                                                                :described => @assignment })
          make_request
        end

      end

      describe 'if the assignment cannot be saved' do

        before do
          @assignment.stub!(:save).and_return(false)
        end

        it 'should render the "new" template' do
          make_request
          response.should render_template('new')
        end
      end
    end
  end

  describe 'GET #show' do

    before do
      @campaign = mock_model(Campaign, :editable? => true,
                                       :visible? => true,
                                       :assignments => [])
      Campaign.stub!(:find).and_return(@campaign)
      @default_params = { :campaign_id => 55, :id => 22 }
      @mock_assignment = mock_model(Assignment, :task_type => 'write_to_other')
      @campaign.assignments.stub!(:find).and_return(@mock_assignment)
    end

    def make_request(params=@default_params)
      get :show, params
    end

    it_should_behave_like "an action requiring a visible campaign"

    it 'should get the assignment' do
      @campaign.assignments.should_receive(:find).with("22")
      make_request
    end

    describe 'if the assignment task type is "write_to_transport_organization"' do

      before do
        @mock_assignment.stub!(:task_type).and_return('write_to_transport_organization')
      end

      it 'should return a 404' do
        make_request
        response.status.should == '404 Not Found'
      end

    end

    describe 'if the assignment task type is "write_to_other"' do

      before do
        @mock_assignment.stub!(:task_type).and_return('write_to_other')
      end

      it 'should render the "show" template' do
        make_request
        response.should render_template('show')
      end

    end

  end

  describe 'GET #edit' do

    before do
      @default_params = { :campaign_id => 55, :id => 1 }
      @expected_access_message = :assignments_edit_access_message
      @mock_assignment = mock_model(Assignment)
      @campaign_user = mock_model(User, :name => 'Test Name')
      @mock_campaign = mock_model(Campaign, :assignments => [@mock_assignment],
                                            :editable? => true,
                                            :visible? => true,
                                            :initiator => @campaign_user)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @mock_campaign.assignments.stub!(:find).and_return(@mock_assignment)
    end

    def make_request(params)
      get :edit, params
    end

    it_should_behave_like "an action that requires the campaign initiator"

    describe 'when responding to a request from the campaign initiator' do

      before do
        @controller.stub!(:current_user).and_return(@campaign_user)
      end

      it 'should return a 404 if the assignment is not to find a transport organization or the contact details for one' do
        @mock_assignment.stub!(:task_type).and_return('some_other_assignment')
        make_request(@default_params)
        response.status.should == '404 Not Found'
      end

      it 'should render the "edit" template if the task is to find a transport organization' do
        @mock_assignment.stub!(:task_type).and_return('find_transport_organization')
        make_request(@default_params)
        response.should render_template("edit")
      end

      it 'should render the "edit" template if the task is to find contact details for a transport organization' do
        @mock_assignment.stub!(:task_type).and_return('find_transport_organization_contact_details')
        make_request(@default_params)
        response.should render_template("edit")
      end

    end

  end

  describe 'PUT #update' do

    before do
      @default_params = { :campaign_id => 55, :id => 1, :organization_name => 'test name'}
      @expected_access_message = :assignments_update_access_message
      @mock_assignment = mock_model(Assignment, :data= => true,
                                                :status= => true,
                                                :save => false)
      @mock_user = mock_model(User, :name => 'Test Name')
      @mock_campaign = mock_model(Campaign, :assignments => [@mock_assignment],
                                            :editable? => true,
                                            :visible? => true,
                                            :initiator => @mock_user,
                                            :campaign_events => [])
      Campaign.stub!(:find).and_return(@mock_campaign)
      @mock_campaign.assignments.stub!(:find).and_return(@mock_assignment)
    end

    def make_request(params)
      put :update, params
    end

    it_should_behave_like "an action that requires the campaign initiator"

    describe 'when responding to a request from the campaign initiator' do

      before do
        @controller.stub!(:current_user).and_return(@mock_user)
      end

      it 'should return a 404 if the assignment is not to find a transport organization or the contact details for one' do
        @mock_assignment.stub!(:task_type).and_return('some_other_assignment')
        make_request(@default_params)
        response.status.should == '404 Not Found'
      end

      describe 'when the assignment is to find a transport organization' do

        before do
          @mock_assignment.stub!(:task_type).and_return("find_transport_organization")
          CampaignMailer.stub!(:deliver_completed_assignment)
        end

        it 'should set the status of the assignment to "in-progress"' do
          @mock_assignment.should_receive(:status=).with(:in_progress)
          make_request(@default_params)
        end

        it 'should add the organization name to the assignment data' do
          @mock_assignment.should_receive(:data=).with({ :organization_name => 'test name',
                                                         :organization_email => nil })
          make_request(@default_params)
        end

        it 'should try and save the assignment' do
          @mock_assignment.should_receive(:save)
          make_request(@default_params)
        end

        describe 'when the assignment cannot be saved' do

          before do
            @mock_assignment.stub!(:save).and_return(false)
          end

          it 'should render the "edit" template' do
            make_request(@default_params)
            response.should render_template("edit")
          end

        end

        describe 'when the assignment can be saved' do

          before do
            @mock_assignment.stub!(:save).and_return(true)
            @mock_campaign.campaign_events.stub!(:create!)
          end

          it 'should send a notification that an assignment has been attempted' do
            CampaignMailer.should_receive(:deliver_completed_assignment)
            make_request(@default_params)
          end

          it 'should redirect to the campaign page' do
            make_request(@default_params)
            response.should redirect_to campaign_path(@mock_campaign)
          end

          it 'should show a notice that the company and contact information will be added to the database' do
            make_request(@default_params)
            flash[:notice].should == "Well done, as soon as we've added the company and contact information into the database, your problem will be on its way!"
          end

          it 'should add a campaign event that the assignment is in progress' do
            @mock_campaign.campaign_events.should_receive(:create!).with(:event_type => 'assignment_in_progress',
                                                                         :described => @mock_assignment)
            make_request(@default_params)

          end
        end
      end
    end
  end
end