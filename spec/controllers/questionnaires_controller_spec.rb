require 'spec_helper'

describe QuestionnairesController do

  shared_examples_for "an action that requires a valid questionnaire" do

    it 'should look for the questionnaire by token' do
      Questionnaire.should_receive(:find_by_token).with('mytoken')
      make_request
    end

    describe 'if the questionnaire cannot be found' do

      before do
        Questionnaire.stub!(:find_by_token).and_return(nil)
      end

      it 'should redirect to the front page' do
        make_request
        response.should redirect_to(root_url)
      end

      it 'should show an error message' do
        make_request
        flash[:error].should == "We're sorry, but we could not find that questionnaire. If you are having issues, try copying and pasting the URL from your email into your browser. If that doesn't work, use the feedback link to get in touch."
      end

    end

    describe 'if the questionnaire can be found' do

      it 'should set up map params from the questionnaire issue location' do
        controller.should_receive(:map_params_from_location).with(@stop.points,
                                                                  find_other_locations=false,
                                                                  LOCATION_PAGE_MAP_HEIGHT,
                                                                  LOCATION_PAGE_MAP_WIDTH)
        make_request
      end

      it 'should try to log in the questionnaire user' do
        UserSession.should_receive(:login_by_confirmation)
        make_request
      end

      describe 'if the subject of the questionnaire is hidden' do

        before do
          @problem.stub!(:visible?).and_return(false)
        end

        it 'should show an error message' do
          make_request
          flash[:error].should == 'Unable to access questionnaire: this issue has been removed.'
        end

        it 'should redirect to the front page' do
          make_request
          response.should redirect_to(root_url)
        end

      end

      describe 'if login by confirmation does not return a session (indicating the user is suspended)' do

        before do
          UserSession.stub(:login_by_confirmation).and_return(nil)
        end

        it 'should show a suspension error message' do
          make_request
          flash[:error].should == 'Unable to access questionnaire: this account has been suspended.'
        end

        it 'should redirect to the front page' do
          make_request
          response.should redirect_to(root_url)
        end

      end

      describe 'if login by confirmation returns a session' do


        describe 'if the questionnaire has been completed' do

          before do
            @questionnaire.stub!(:completed_at).and_return(Time.now - 1.day)
          end

          it 'should show an error message' do
            make_request
            flash[:error].should match("You've already answered this questionnaire.")
          end

          it 'should redirect to the front page' do
            make_request
            response.should redirect_to(root_url)
          end

        end

      end

    end

  end

  describe 'GET #show' do

    def make_request
      get :show, { :email_token => 'mytoken' }
    end

    before do
      @user = mock_model(User)
      @stop = mock_model(Stop, :points => ['my points'])
      @problem = mock_model(Problem, :location => @stop,
                                     :visible? => true)
      @questionnaire = mock_model(Questionnaire, :subject => @problem,
                                                 :completed_at => nil,
                                                 :user => @user)
      Questionnaire.stub!(:find_by_token).and_return(@questionnaire)
      controller.stub!(:map_params_from_location)
      UserSession.stub!(:login_by_confirmation).and_return(mock_model(UserSession))
    end

    it_should_behave_like "an action that requires a valid questionnaire"

    it "should render the 'show' template" do
      make_request
      response.should render_template('show')
    end

  end

  describe 'POST #update' do

    def make_request(params=@default_params)
      post :update, params
    end

    before do
      @default_params = { :email_token => 'mytoken' }
      @user = mock_model(User, :answered_ever_reported? => false,
                               :update_attribute => nil)
      @stop = mock_model(Stop, :points => ['my points'],
                               :campaigns => mock('campaigns', :visible => []),
                               :name => 'Test Stop',
                               :transport_mode_names => ['Bus/Coach'])
      @comment = mock_model(Comment, :status= => nil,
                                     :save => true,
                                     :confirm! => nil)
      @problem = mock_model(Problem, :location => @stop,
                                     :status_code => 3,
                                     :visible? => true,
                                     :status => :confirmed,
                                     :status= => nil,
                                     :responsible_org_descriptor => 'Test Operator',
                                     :comments => mock('comments', :build => @comment),
                                     :updated_at= => nil,
                                     :save! => nil)
      @questionnaire = mock_model(Questionnaire, :subject => @problem,
                                                 :completed_at => nil,
                                                 :user => @user,
                                                 :old_status_code= => nil,
                                                 :new_status_code= => nil,
                                                 :ever_reported= => nil,
                                                 :completed_at= => nil,
                                                 :save! => nil)
      Questionnaire.stub!(:find_by_token).and_return(@questionnaire)
      controller.stub!(:map_params_from_location)
      UserSession.stub!(:login_by_confirmation).and_return(mock_model(UserSession))
      controller.stub!(:current_user).and_return(@user)
    end

    it_should_behave_like "an action that requires a valid questionnaire"

    describe 'if the "fixed" parameter is not supplied' do

      it 'should set an error message for the view' do
        make_request
        assigns[:errors][:fixed].should == 'Please say whether the problem has been fixed.'
      end

      it 'should render the "show" template' do
        make_request
        response.should render_template('show')
      end

      it 'should set up map params from the stop' do
        controller.should_receive(:map_params_from_location).with(@stop.points,
                                                                  find_other_locations=false,
                                                                  LOCATION_PAGE_MAP_HEIGHT,
                                                                  LOCATION_PAGE_MAP_WIDTH)
        make_request
      end

    end

    describe 'if the user has never answered the "have you ever reported an issue" question
              and the "ever_reported" param is missing' do

      it 'should set an error message for the view' do
        make_request
        assigns[:errors][:ever_reported].should == 'Please say whether you have ever reported a transport problem before.'
      end

      it 'should render the "show" template' do
        make_request
        response.should render_template('show')
      end

      it 'should set up map params from the stop' do
        controller.should_receive(:map_params_from_location).with(@stop.points,
                                                                  find_other_locations=false,
                                                                  LOCATION_PAGE_MAP_HEIGHT,
                                                                  LOCATION_PAGE_MAP_WIDTH)
        make_request
      end

    end

    describe 'if the "fixed" param is "no" or "unknown" and the "another" param is not supplied' do

      before do
        @params = @default_params.merge(:fixed => 'no')
      end

      it 'should set an error message for the view' do
        make_request(@params)
        assigns[:errors][:another].should == "Please say whether you'd like to receive another questionnaire."
      end

      it 'should render the show template' do
        make_request(@params)
        response.should render_template('show')
      end

      it 'should set up map params from the stop' do
        controller.should_receive(:map_params_from_location).with(@stop.points,
                                                                  find_other_locations=false,
                                                                  LOCATION_PAGE_MAP_HEIGHT,
                                                                  LOCATION_PAGE_MAP_WIDTH)
        make_request(@params)
      end

    end

    describe 'if params are supplied' do

      before do
        @questionnaire.stub!(:ever_reported=)
        @params = @default_params.merge(:ever_reported => 'yes',
                                        :fixed => 'no',
                                        :another => 'no')
      end

      it 'should set the questionnaire "ever_reported" flag' do
        @questionnaire.should_receive(:ever_reported=).with(true)
        make_request(@params)
      end

      it 'should set the "old_status_code" on the questionnaire to the status of the questionnaire subject' do
        @questionnaire.should_receive(:old_status_code=).with(@problem.status_code)
        make_request(@params)
      end

      it 'should set "completed_at" on the questionnaire' do
        @questionnaire.should_receive(:completed_at=)
        make_request(@params)
      end

      it 'should save the issue' do
        @problem.should_receive(:save!)
        make_request(@params)
      end

      it 'should save the questionnaire' do
        @questionnaire.should_receive(:save!)
        make_request(@params)
      end

    end

    describe 'if issue is a problem' do

      before do
        @problem.stub!(:send_questionnaire=)
      end

      describe 'if the "fixed param" is "no"' do

        before do
          @params = @default_params.merge(:ever_reported => 'yes',
                                          :fixed => 'no',
                                          :another => 'yes',
                                          :update => 'test update')
        end

        describe 'if there are existing campaigns at the location' do

          before do
            @stop.campaigns.stub!(:visible).and_return([mock_model(Campaign)])
          end

          it 'should add a large notice suggesting the user looks for existing campaigns on their issue' do
            make_request(@params)
            expected_notice = ["We're sorry to hear that this problem hasn't been fixed. If it's an ongoing issue,",
                                "you could look to see if anyone is",
                                "<a href=\"/problems/existing?location_id=#{@stop.id}&location_type=Stop&source=questionnaire\">seeking",
                                "support</a> for a similar issue at the Test Stop, and add your voice."].join(" ")
            flash[:large_notice].should == expected_notice
          end

          it 'should redirect to the problem url' do
            make_request(@params)
            response.should redirect_to(problem_url(@problem))
          end

        end

        describe 'if there are no existing campaigns at the location' do

          before do
            @stop.campaigns.stub!(:visible).and_return([])
          end

          it 'should add a large notice suggesting a campaign, linking to the new problem
              page, passing a reference_id param with the current problem id' do
            make_request(@params)
            expected_url = "/problems/new?location_id=#{@stop.id}&location_type=Stop&reference_id=#{@problem.id}"
            expected_notice = ["We're sorry to hear that this problem hasn't been fixed. If it's",
                              "an ongoing issue, you could use FixMyTransport to get others involved by",
                              "<a href=\"#{expected_url}\">writing",
                              "another message to Test Operator</a>. We'll make a public page for gathering",
                              "support and any replies you get will appear there. We'll also give you tools",
                              "for spreading the word and getting expert advice."].join(" ")
            flash[:large_notice].should == expected_notice
          end

          it 'should redirect to the problem url' do
            make_request(@params)
            response.should redirect_to(problem_url(@problem))
          end

        end

      end

      describe 'if the "fixed" param is "unknown"' do

        before do
          @params = @default_params.merge(:ever_reported => 'yes',
                                          :fixed => 'unknown',
                                          :another => 'yes',
                                          :update => 'test update')
        end

        it 'should add a large notice asking the user to add an update if they get more information' do
          make_request(@params)
          flash[:large_notice].should == 'Thank you very much for filling in our questionnaire. Please do come and leave an update if you get more information about the status of your problem.'
        end

        it 'should redirect to the problem url' do
          make_request(@params)
          response.should redirect_to(problem_url(@problem))
        end

      end

    end

    describe 'if the issue is a campaign' do

      before do
        @campaign = mock_model(Campaign, :send_questionnaire= => nil,
                                         :visible? => true,
                                         :status => :confirmed,
                                         :status_code => 1,
                                         :updated_at= => nil,
                                         :save! => nil,
                                         :comments => mock('comments', :build => @comment))
        @questionnaire.stub!(:subject).and_return(@campaign)

      end

      describe 'if the "fixed" param is "no"' do

        before do
          @params = @default_params.merge(:ever_reported => 'yes',
                                          :fixed => 'no',
                                          :another => 'yes',
                                          :update => 'test update')
        end

        it 'should add a large notice suggesting asking for advice' do
          make_request(@params)
          flash[:large_notice].should == "We're sorry to hear that this problem hasn't been fixed. If you're stuck for what to do next, use the \"Ask an expert\" button to ask your supporters and our experts for advice."
        end

        it 'should redirect to the campaign url' do
          make_request(@params)
          response.should redirect_to(campaign_url(@campaign))
        end

      end

      describe 'if the "fixed" param is "unknown"' do

        before do
          @params = @default_params.merge(:ever_reported => 'yes',
                                          :fixed => 'unknown',
                                          :another => 'yes',
                                          :update => 'test update')
        end

        it 'should add a large notice asking the user to add an update if they get more information' do
          make_request(@params)
          flash[:large_notice].should == 'Thank you very much for filling in our questionnaire. Please do come and leave an update if you get more information about the status of your problem.'
        end

        it 'should redirect to the campaign url' do
          make_request(@params)
          response.should redirect_to(campaign_url(@campaign))
        end
      end

    end


    describe 'if the "another" param is "yes"' do

      before do
        @problem.stub!(:send_questionnaire=)
        @params = @default_params.merge(:ever_reported => 'yes',
                                        :fixed => 'no',
                                        :another => 'yes')
      end

      it 'should set the send_questionnaire flag on the questionnaire subject' do
        @problem.should_receive(:send_questionnaire=).with(true)
        make_request(@params)
      end

    end

    describe 'if the issue was fixed and the user has reported it as not fixed' do

      before do
        @problem.stub!(:status).and_return(:fixed)
      end

      describe 'if there is no update' do

        before do
          @problem.stub!(:status).and_return(:fixed)
          @params = @default_params.merge(:ever_reported => 'yes',
                                          :fixed => 'no',
                                          :another => 'no')
        end

        it 'should set an error message for the view' do
          make_request(@params)
          assigns[:errors][:update].should == "Please provide an explanation as to why you're reopening this report."
        end

        it 'should render the "show" template' do
          make_request(@params)
          response.should render_template('show')
        end

      end

      describe 'if there is an update' do

        before do
          @params = @default_params.merge(:ever_reported => 'yes',
                                          :fixed => 'no',
                                          :update => 'test update',
                                          :another => 'no')
        end

        it 'should set the issue status to confirmed' do
          @problem.should_receive(:status=).with(:confirmed)
          make_request(@params)
        end

        it 'should add the update comment to the issue' do
          expected_data = { :text => 'test update',
                            :model => @problem,
                            :mark_open => true,
                            :mark_fixed => nil,
                            :confirmed => true }
          Comment.should_receive(:create_from_hash).with(expected_data, @user)
          make_request(@params)
        end


        describe 'if the status has not changed' do

          before do
            @problem.stub!(:status).and_return(:confirmed)
          end

          it 'should update the timestamp on the issue' do
            @problem.should_receive(:updated_at=)
            make_request(@params)
          end

        end


        it 'should set the "new_status_code" on the questionnaire to confirmed' do
          @questionnaire.should_receive(:new_status_code=).with(3)
          make_request(@params)
        end

      end


    end

    describe 'if the issue was confirmed and the user has reported it as fixed' do

      before do
        @problem.stub!(:status).and_return(:confirmed)
        @params = @default_params.merge(:ever_reported => 'yes', :fixed => 'yes')
      end

      it 'should set the issue status to fixed' do
        @problem.should_receive(:status=).with(:fixed)
        make_request(@params)
      end

      it 'should set the "new_status_code" on the questionnaire' do
        @questionnaire.should_receive(:new_status_code=).with(3)
        make_request(@params)
      end

      it 'should render the "completed" template' do
        make_request(@params)
        response.should render_template('completed')
      end

      describe 'if there is an update' do

        before do
          @params = @default_params.merge(:ever_reported => 'yes', :fixed => 'yes', :update => 'test update')
        end

        it 'should add the update comment to the issue' do
          expected_data = { :text => 'test update',
                            :model => @problem,
                            :mark_open => nil,
                            :mark_fixed => true,
                            :confirmed => true }
          Comment.should_receive(:create_from_hash).with(expected_data, @user)
          make_request(@params)
        end

      end

      describe 'if there is no update' do

        it 'should add a comment to the issue saying that the user filled in a questionnaire' do
          expected_data = { :text => 'Questionnaire filled in by problem reporter.',
                            :model => @problem,
                            :mark_open => nil,
                            :mark_fixed => true,
                            :confirmed => true }
          Comment.should_receive(:create_from_hash).with(expected_data, @user)
          make_request(@params)
        end

      end

    end

    describe "if the issue was confirmed and the user has reported that they don't know if it's fixed" do

      before do
        @problem.stub!(:status).and_return(:confirmed)
        @params = @default_params.merge(:ever_reported => 'yes',
                                        :fixed => 'unknown',
                                        :update => 'test update',
                                        :another => 'no')
      end

      it 'should not change the status of the issue' do
        @problem.should_not_receive(:status=)
        make_request(@params)
      end

      it 'should set the "new_status_code" on the questionnaire to confirmed' do
        @questionnaire.should_receive(:new_status_code=).with(3)
        make_request(@params)
      end

    end


  end

  describe 'GET #creator_fixed' do

    before do
      @default_params = { :id => 55, :type => 'Problem' }
    end

    def make_request(params=@default_params)
      get :creator_fixed, params
    end

    describe 'if no id param is given' do

      it 'should redirect to the front page' do
        make_request({})
        response.should redirect_to(root_url)
      end

      it 'should show an error message' do
        make_request({})
        flash[:error].should == "Sorry, we couldn't find your issue in the database."
      end

    end

    describe 'if no valid type param is given' do

      it 'should redirect to the front page' do
        make_request({:id => 55, :type => "Stop"})
        response.should redirect_to(root_url)
      end

      it 'should show an error message' do
        make_request({:id => 55, :type => "Stop"})
        flash[:error].should == "Sorry, we couldn't find your issue in the database."
      end

    end

    describe "if the user is not associated with the issue" do

      before do
        @user = mock_model(User)
        @other_user = mock_model(User)
        @problem = mock_model(Problem, :reporter => @other_user)
        Problem.stub!(:find).and_return(@problem)
        controller.stub!(:current_user).and_return(@user)
      end

      it 'should redirect to the front page' do
        make_request()
        response.should redirect_to(root_url)
      end

      it 'should show an error message' do
        make_request()
        flash[:error].should == "Sorry, we couldn't find your issue in the database."
      end

    end

    describe 'if the user is associated with the issue' do

      before do
        @user = mock_model(User)
        @stop = mock_model(Stop, :points => ['my points'])
        @problem = mock_model(Problem, :reporter => @user,
                                       :location => @stop)
        Problem.stub!(:find).and_return(@problem)
        controller.stub!(:current_user).and_return(@user)
      end

      it 'should set up map params from the issue location' do
        controller.should_receive(:map_params_from_location).with(@stop.points,
                                                                  find_other_locations=false,
                                                                  LOCATION_PAGE_MAP_HEIGHT,
                                                                  LOCATION_PAGE_MAP_WIDTH)
        make_request()
      end
    end

  end

  describe 'POST #creator_fixed' do

    before do
      @default_params = { :id => 55, :type => 'Problem' }
      @user = mock_model(User)
      @stop = mock_model(Stop, :points => ['my points'],
                               :name => 'test stop')
      @problem = mock_model(Problem, :reporter => @user,
                                     :location => @stop,
                                     :status_code => 5)
      Problem.stub!(:find).and_return(@problem)
      controller.stub!(:current_user).and_return(@user)
      controller.stub!(:map_params_from_location)
    end

    def make_request(params=@default_params)
      post :creator_fixed, params
    end

    describe 'if there is no "ever_reported" parameter supplied' do

      it 'should add an error to the error hash assigned to the view' do
        make_request()
        assigns[:errors][:ever_reported].should == 'Please say whether you have ever reported a transport problem before.'
      end

      it 'should render the "creator_fixed" template' do
        make_request()
        response.should render_template('creator_fixed')
      end


      it 'should set up map params from the issue location' do
        controller.should_receive(:map_params_from_location).with(@stop.points,
                                                                  find_other_locations=false,
                                                                  LOCATION_PAGE_MAP_HEIGHT,
                                                                  LOCATION_PAGE_MAP_WIDTH)
        make_request()
      end

    end

    describe 'if the "ever_reported" parameter is supplied' do

      before do
        @params = @default_params.merge(:ever_reported => 'no')
        controller.stub!(:map_params_from_location)
        @questionnaire = mock_model(Questionnaire, :old_status_code= => nil)
        Questionnaire.stub!(:create!).and_return(@questionnaire)
        controller.stub!(:flash).and_return({:old_status_code => 4})
        @time_now = Time.parse("Feb 24 1981")
        Time.stub!(:now).and_return(@time_now)
      end

      it 'should create a new questionnaire' do
        Questionnaire.should_receive(:create!).with(:subject => @problem,
                                                    :user => @user,
                                                    :old_status_code => 4,
                                                    :new_status_code => 5,
                                                    :ever_reported => false,
                                                    :sent_at => @time_now,
                                                    :completed_at => @time_now)
        make_request(@params)
      end

      it 'should render the "completed" template' do
        make_request(@params)
        response.should render_template('completed')
      end

    end

  end

end
