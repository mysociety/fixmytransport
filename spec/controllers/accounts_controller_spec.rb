require 'spec_helper'

describe AccountsController do

  shared_examples_for "an action requiring a logged-in user" do

    it 'should require a logged-in user' do
      make_request
      flash[:notice].should == 'You must be logged in to access this page.'
    end

    describe 'if the logged-in user is suspended' do

      before do
        controller.stub!(:current_user).and_return(mock_model(User, :suspended? => true))
      end

      it 'should destroy the user session and return an error message saying the account is suspended' do
        user_session_mock = mock('User session')
        controller.stub!(:current_user_session).and_return(user_session_mock)
        user_session_mock.should_receive(:destroy)
        make_request
        flash[:error].should == 'Unable to authenticate &mdash; this account has been suspended.'
      end

    end

  end

  describe 'GET #edit' do

    def make_request
      get :edit
    end

    it_should_behave_like 'an action requiring a logged-in user'

    describe 'when a user is logged in' do

      before do
        @mock_user = mock_model(User, :errors => mock('errors', :on => []),
                                      :name => '',
                                      :email => '',
                                      :password => '',
                                      :password_confirmation => '',
                                      :suspended? => false)
        controller.stub!(:current_user).and_return(@mock_user)
      end

      it 'should render the edit template' do
        make_request
        response.should render_template("edit")
      end

    end

  end

  describe 'PUT #update' do

    before do
      @default_params = { :user => { :email => 'test@example.com' } }
    end

    def make_request(params=@default_params)
      put :update, params
    end

    it_should_behave_like 'an action requiring a logged-in user'

    describe 'when a user is logged in' do

      before do
        @mock_user = mock_model(User, :email= => true,
                                      :password= => true,
                                      :password_confirmation= => true,
                                      :save => true,
                                      :update_attributes => true,
                                      :suspended? => false)
        controller.stub!(:current_user).and_return(@mock_user)
      end

      it 'should update the current users account info' do
        @mock_user.should_receive(:email=).with('test@example.com')
        make_request(@default_params)
      end

      describe 'if the user enters a password' do

        it 'should set the account as registered and set the confirmed password flag and force validation as if a new record' do
          @mock_user.should_receive(:registered=).with(true)
          @mock_user.should_receive(:confirmed_password=).with(true)
          @mock_user.should_receive(:force_new_record_validation=).with(true)
          make_request(@default_params.merge({:user => {:password => 'password'}}))
        end

      end

      describe 'if the user adds a profile photo' do

        it 'should set the profile photo remote url to nil' do
          @mock_user.should_receive(:profile_photo_remote_url=).with(nil)
          make_request(@default_params.merge({:user => {:profile_photo => mock('profile photo')}}))
        end

      end

      describe 'if the update is successful' do

        it "should redirect to the user's profile page" do
          make_request(@default_params)
          response.should redirect_to(profile_path(@mock_user))
        end

      end

      describe 'if the update is not successful' do

        before do
          @mock_user.stub!(:save).and_return(false)
        end

        it 'should render the edit template' do
          make_request(@default_params)
          response.should render_template('edit')
        end

      end

    end

  end

  describe 'GET #new' do

    def make_request
      get :new
    end

    it 'should not require a logged-in user' do
      make_request
      flash[:notice].should be_nil
    end

    it 'should render the "new" template' do
      make_request
      response.should render_template('new')
    end

  end

  describe 'POST #create' do

    before do
      @mock_user = mock_model(User, :valid? => false,
                                    :name= => nil,
                                    :email= => nil,
                                    :password= => nil,
                                    :password_confirmation= => nil,
                                    :ignore_blank_passwords= => nil,
                                    :force_new_record_validation= => nil,
                                    :registered= => true,
                                    :new_record? => true,
                                    :registered? => false,
                                    :save_without_session_maintenance => true,
                                    :reset_perishable_token! => true,
                                    :perishable_token => 'mytoken',
                                    :suspended? => false,
                                    :post_login_action= => nil)
      User.stub!(:find_or_initialize_by_email).and_return(@mock_user)
      UserMailer.stub!(:deliver_new_account_confirmation)
      ActionConfirmation.stub!(:create!)
    end

    def make_request(format="html")
      post :create, { :user => { :name => 'A name',
                                 :email => 'new_user@example.com',
                                 :password => "A password",
                                 :password_confirmation => "A password confirmation" },
                      :format => format }
    end

    it 'should find or initialize a user object using the email address' do
      User.should_receive(:find_or_initialize_by_email).with("new_user@example.com").and_return(@mock_user)
      make_request
    end

    it 'should set attributes on the user object based on the form params' do
      @mock_user.should_receive(:name=).with("A name")
      @mock_user.should_receive(:password=).with("A password")
      @mock_user.should_receive(:password_confirmation=).with("A password confirmation")
      make_request
    end

    it 'should test the user object to see if it is valid' do
      @mock_user.should_receive(:valid?).and_return(true)
      make_request
    end

    describe 'if the user model is valid' do

      before do
        @mock_user.stub!(:valid?).and_return(true)
      end

      describe 'if this is a new email address' do

        before do
          @mock_user.stub!(:new_record?).and_return(true)
        end

        it 'should save the user (not logging them in)' do
          @mock_user.should_receive(:save_without_session_maintenance)
          make_request
        end

        it 'should ask the user mailer to send an account confirmation email' do
          UserMailer.should_receive(:deliver_new_account_confirmation)
          make_request
        end

        it 'should save the next action to the database' do
          @controller.should_receive(:save_post_login_action_to_database)
          make_request
        end

        describe 'if there is no post login action set' do

          before do
            @controller.stub!(:get_action_data).and_return(nil)
          end

          it 'should set the action message for the confirmation template to an account confirmation message' do
            make_request
            assigns[:action].should == "your account won't be created."
          end

          it 'should create an action confirmation without a target' do
            ActionConfirmation.should_receive(:create!).with(:user => @mock_user,
                                                             :token => 'mytoken')
            make_request
          end

        end

        describe 'if the post login action is to add a comment' do 
          
          before do 
            @mock_comment = mock_model(Comment)
            @controller.stub!(:get_action_data).and_return({:action => :add_comment,
                                                            :commented_type => 'Problem',
                                                            :id => 44})
            @mock_problem = mock_model(Problem)
            Problem.stub!(:find).and_return(@mock_problem)
            Comment.stub!(:create_from_hash).and_return(@mock_comment)
          end
        
          it 'should set the action for the confirmation template to a comment confirmation message' do 
            make_request
            assigns[:action].should == 'your comment will not be added.'
          end
        
          it 'should create a comment from the post action data hash' do 
            Comment.should_receive(:create_from_hash).and_return(@mock_comment)
            make_request
          end
        
          it 'should create an action confirmation with the comment as the target' do 
            ActionConfirmation.should_receive(:create!).with(:user => @mock_user, 
                                                             :token => 'mytoken', 
                                                             :target => @mock_comment)
            make_request
          end
        
        end
        
        describe 'if the post login action is to join a campaign' do 
        
          before do
            @controller.stub!(:get_action_data).and_return({:action => :join_campaign})
            @mock_campaign = mock_model(Campaign)
            Campaign.stub!(:find).and_return(@mock_campaign)
            @mock_supporter = mock_model(CampaignSupporter)
            @mock_campaign.stub!(:add_supporter).and_return(@mock_supporter)
          end
          
          it 'should set the action for the confirmation template to a support confirmation message' do 
            make_request
            assigns[:action].should == 'you will not be added as a supporter.'
          end
          
          it 'should add the user as a supporter for the campaign' do 
            @mock_campaign.should_receive(:add_supporter).and_return(@mock_supporter)
            make_request
          end
        
          it 'should create an action confirmation with the campaign support as the target' do 
            ActionConfirmation.should_receive(:create!).with(:user => @mock_user, 
                                                             :token => 'mytoken', 
                                                             :target => @mock_supporter)
            make_request
          end
                    
        end
        
        describe 'if the post login action is to create a problem' do

          before do
            @mock_problem = mock_model(Problem)
            @controller.stub!(:get_action_data).and_return({:action => :create_problem})
            Problem.stub!(:create_from_hash).and_return(@mock_problem)
          end

          it 'should set the action for the confirmation template to a problem creation message' do
            make_request
            assigns[:action].should == "your problem will not be sent."
          end

          it 'should create a problem from the post action data hash' do
            Problem.should_receive(:create_from_hash).and_return(@mock_problem)
            make_request
          end
          
          it 'should create an action confirmation with the problem as the target' do 
            ActionConfirmation.should_receive(:create!).with(:user => @mock_user, 
                                                             :token => 'mytoken', 
                                                             :target => @mock_problem)
            make_request
          end

        end

        describe 'if the request asks for html' do

          it 'should render the "confirmation_sent" template' do
            make_request
            response.should render_template("shared/confirmation_sent")
          end

        end

        describe 'if the request asks for json' do

          it 'should return the "confirmation_sent" template rendered as a string in the response' do
            @controller.stub!(:render_to_string).with(:template => 'shared/confirmation_sent', :layout => 'confirmation').and_return("content")
            make_request(format="json")
            JSON.parse(response.body)['html'].should == "content"
          end
        end

      end

      describe 'if this is an email address that has an unregistered account' do

        before do
          @mock_user.stub!(:new_record?).and_return(false)
          @mock_user.stub!(:registered?).and_return(false)
          UserMailer.stub!(:deliver_account_exists)
        end

        it 'should ask the user mailer to send an "already exists" email' do
          UserMailer.should_receive(:deliver_account_exists)
          make_request
        end

        it 'should render the "confirmation_sent" template' do
          make_request
          response.should render_template("shared/confirmation_sent")
        end

      end

      describe 'if this is an email address that has a registered account' do

        before do
          @mock_user.stub!(:new_record?).and_return(false)
          @mock_user.stub!(:registered?).and_return(true)
          UserMailer.stub!(:deliver_already_registered)
        end

        it 'should ask the user mailer to send an "already registered" email' do
          UserMailer.should_receive(:deliver_already_registered)
          make_request
        end

        it 'should render the "confirmation_sent" template' do
          make_request
          response.should render_template("shared/confirmation_sent")
        end

      end

    end

    describe 'if the user model is not valid' do

      describe 'if the user model is not a new record' do

        before do
          @clone_mock_user = mock_model(User,
                                        :skip_email_uniqueness_validation => nil,
                                        :skip_email_uniqueness_validation= => true,
                                        :password= => true,
                                        :valid? => false,
                                        :password_confirmation= => true)
          @mock_user.stub!(:new_record?).and_return(false)
          @mock_user.stub!(:valid?).and_return(false)
          @mock_user.stub!(:clone).and_return(@clone_mock_user)
        end

        it 'should clone the model' do
          @mock_user.should_receive(:clone).and_return(@clone_mock_user)
          make_request
        end

        it 'should set the flag to skip the email uniqueness validation' do
          @clone_mock_user.should_receive(:skip_email_uniqueness_validation=).with(true)
          make_request
        end

        it 'should validate the model' do
          @clone_mock_user.should_receive(:valid?).and_return(false)
          make_request
        end

      end

      before do
        @mock_user.stub!(:valid?).and_return(false)
        @mock_user.stub!(:new_record?).and_return(true)
        @mock_user.stub!(:errors).and_return([[:base, "Test error message"]])
      end

      describe 'if the request asks for html' do

        it 'should render the "new" template' do
          make_request
          response.should render_template('new')
        end

      end

      describe 'if the request asks for json' do

        it 'should return a json hash with a key for errors' do
          make_request(format="json")
          JSON.parse(response.body)['errors'].should == {'base' => 'Test error message'}
        end

        it 'should return a json hash with a success key set to false' do
          make_request(format="json")
          JSON.parse(response.body)['success'].should == false
        end

      end
    end

  end


  describe 'GET #confirm' do

    def make_request
      post :confirm, :email_token => 'my_token'
    end

    it 'should look for an action confirmation by token' do
      ActionConfirmation.should_receive(:find_by_token)
      make_request
    end

    describe 'if no confirmation is found using the action confirmation token' do

      before do
        ActionConfirmation.stub!(:find_by_token).with('my_token', :include => :user).and_return(nil)
      end

      it 'should show an error message saying that the account cannot be found' do
        make_request
        flash[:error].should == "We're sorry, but we could not locate your account. If you are having issues, try copying and pasting the URL from your email into your browser. If that doesn't work, use the feedback link to get in touch."
      end

      it 'should redirect to the root url' do
        make_request
        response.should redirect_to(root_url)
      end

    end

    describe 'if a user can be found using the action confirmation token' do

      before do
        UserSession.stub!(:login_by_confirmation)
        @mock_user = mock_model(User, :registered? => false,
                                      :registered= => true,
                                      :confirmed_password= => true,
                                      :crypted_password => "password",
                                      :post_login_action => nil,
                                      :save_without_session_maintenance => true,
                                      :suspended? => false)
        @mock_action_confirmation = mock_model(ActionConfirmation, :user => @mock_user,
                                                                   :target => nil)
        ActionConfirmation.stub!(:find_by_token).with('my_token', :include => :user).and_return(@mock_action_confirmation)
      end

      describe 'if that user is already logged in' do

        before do
          @controller.stub!(:current_user).and_return(@mock_user)
        end

        it 'should show a notice saying that the user has confirmed their account' do
          make_request
          flash[:notice].should == 'You have successfully confirmed your account.'
        end

      end

      describe 'if another user is already logged in' do

        before do
          @other_user = mock_model(User)
          @controller.stub!(:current_user).and_return(@other_user)
        end

        it 'should redirect the user to the front page' do
          make_request
          response.should redirect_to(root_url)
        end

        it "should show them a message that you can't be logged in to access that url" do
          make_request
          flash[:notice].should == 'You must be logged out to access this page'
        end

      end

      it 'should redirect to the saved location or the front of the application' do
        make_request
        response.should redirect_to(root_url)
      end

      it 'should show a notice saying that the user has confirmed their account' do
        make_request
        flash[:notice].should == 'You have successfully confirmed your account.'
      end

      describe 'if the user model is suspended' do

        before do
          @mock_user.stub!(:suspended?).and_return(true)
        end

        it 'should fail by showing an error message saying that the account is suspended' do
          make_request
          flash[:error].should == "Unable to authenticate &mdash; this account has been suspended."
        end

      end

      describe 'if the action confirmation has a target' do


        describe 'if the target is a campaign supporter model' do

          before do
            @mock_campaign = mock_model(Campaign)
            @mock_supporter = mock_model(CampaignSupporter, :confirm! => true,
                                                            :campaign => @mock_campaign)
            @mock_action_confirmation.stub!(:target).and_return(@mock_supporter)
          end

          it 'should confirm the campaign support' do
            @mock_supporter.should_receive(:confirm!)
            make_request
          end

          it 'should the redirect to the campaign path' do
            make_request
            response.should redirect_to(campaign_url(@mock_campaign))
          end

          it 'should show a notice telling the user they have confirmed their campaign membership' do
            make_request
            flash[:notice].should == 'You have successfully confirmed your support for this issue.'
          end
          
        end

        describe 'if the target is a problem' do

          before do
            @mock_problem = mock_model(Problem, :status => :new, 
                                                :created_at => (Time.now - 2.days))
            @mock_action_confirmation.stub!(:target).and_return(@mock_problem)
          end

          it 'should redirect to the problem conversion url' do
            make_request
            response.should redirect_to(convert_problem_url(@mock_problem))
          end

          it 'should show a notice telling the user that they have confirmed their account and need to pick an option to send their problem report' do
            make_request
            flash[:notice].should == "You've successfully confirmed your account. <strong>Decide if you want other people's support and we'll send your problem report on its way.</strong>"
          end
          
          describe 'if the problem is not new' do 
            
            before do 
              @mock_problem.stub!(:status).and_return(:confirmed)
            end
            
            it 'should redirect to the problem conversion url' do
              make_request
              response.should redirect_to(convert_problem_url(@mock_problem))
            end
            
            it 'should show a notice telling the user that they have confirmed the problem report' do
              make_request
              flash[:notice].should == "You've successfully confirmed your problem report."
            end
          
          end
          
          describe 'if the problem is new and more than a month old' do 
            
            before do
              @mock_problem.stub!(:created_at).and_return(Time.now - (1.month + 1.day))
            end          
            
            it 'should not log the user in' do 
              UserSession.should_not_receive(:login_by_confirmation).with(@mock_user)
              make_request
            end
            
            it 'should redirect to the front page' do 
              make_request
              response.should redirect_to(root_url)
            end
            
            it 'should display a message about token expiry' do 
              make_request
              flash[:error].should == "Sorry, we can't validate that token, as the problem report was made too long ago."
            end
            
          end

        end

        describe 'if the target is a comment' do

          before do
            @mock_problem = mock_model(Problem)
            @mock_comment = mock_model(Comment, :confirm! => true, 
                                                :commented => @mock_problem,
                                                :created_at => (Time.now - 1.day),
                                                :status => :new)
            @mock_action_confirmation.stub!(:target).and_return(@mock_comment)
          end

          it 'should confirm the comment' do
            @mock_comment.should_receive(:confirm!)
            make_request
          end

          it 'should redirect to the url of the thing being commented on' do
            make_request
            response.should redirect_to(problem_url(@mock_problem))
          end

          it 'should show a notice telling the user that they have confirmed their comment' do
            make_request
            flash[:notice].should == 'You have successfully confirmed your comment.'
          end
          
          describe 'if the comment is unconfirmed and more than a month old' do 
            
            before do 
              @mock_comment.stub!(:created_at).and_return(Time.now - (1.month + 1.day))
            end          
                      
            it 'should not log the user in' do 
              UserSession.should_not_receive(:login_by_confirmation).with(@mock_user)
              make_request
            end
            
            it 'should redirect to the front page' do 
              make_request
              response.should redirect_to(root_url)
            end
            
            it 'should display a message about token expiry' do 
              make_request
              flash[:error].should == "Sorry, we can't validate that token, as the comment was made too long ago."
            end
            
          end

        end

      end

      describe 'if the user has a crypted password' do

        it 'should show a notice that the user has confirmed their account' do
          make_request
          flash[:notice].should == 'You have successfully confirmed your account.'
        end

        it 'should set the user to registered' do
          @mock_user.should_receive(:registered=).with(true)
          make_request
        end

      end

      describe "if the user doesn't have a crypted password" do

        before do
          @mock_user.stub!(:crypted_password).and_return(nil)
        end

        it 'should show a notice saying that the user has logged in and should set a password' do
          make_request
          flash[:notice].should == "You've successfully logged in. Set a password on your account to make it easier to come back."
        end

        it "should redirect to the user's account if there is no redirect defined by a post-login action" do
          make_request
          response.should redirect_to(edit_account_url)
        end

      end

      it 'should log the user in' do
        UserSession.should_receive(:login_by_confirmation).with(@mock_user)
        make_request
      end

    end

  end

end