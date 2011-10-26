require 'spec_helper'

describe PasswordResetsController do

  shared_examples_for "an action requiring an action confirmation token" do

    it 'should look for an action confirmation by token' do
      ActionConfirmation.should_receive(:find_by_token)
      make_request
    end

    describe 'if an unregisted user is found using the perishable token' do

      it 'should show a notice saying that the account cannot be found' do
        make_request
        flash[:error].should == "We're sorry, but we could not locate your account. If you are having issues, try copying and pasting the URL from your email into your browser. If that doesn't work, use the feedback link to get in touch."
      end

      it 'should redirect to the root url' do
        make_request
        response.should redirect_to(root_url)
      end

    end

    describe 'if no user can be found using the perishable token param' do

      it 'should show a notice saying that the account cannot be found' do
        make_request
        flash[:error].should == "We're sorry, but we could not locate your account. If you are having issues, try copying and pasting the URL from your email into your browser. If that doesn't work, use the feedback link to get in touch."
      end

      it 'should redirect to the root url' do
        make_request
        response.should redirect_to(root_url)
      end

    end

  end

  describe 'GET #new' do

    def make_request
      get :new
    end

    it 'should render the "new" template' do
      make_request
      response.should render_template('new')
    end

  end

  describe 'GET #edit' do

    def make_request
      get :edit, :email_token => 'mytoken'
    end

    it_should_behave_like "an action requiring an action confirmation token"

    describe 'if a registered user can be found using the perishable token param' do

      before do
        @mock_user = mock_model(User, :registered? => false, 
                                      :suspended? => false)
        @mock_confirmation = mock_model(ActionConfirmation, :user => @mock_user, :target => nil)
        ActionConfirmation.stub!(:find_by_token).with('mytoken', :include => :user).and_return(@mock_confirmation)
      end
      
      it 'should render the "edit" template' do
        make_request
        response.should render_template('edit')
      end

    end

  end

  describe 'POST #create' do

    def make_request(format='html', email="test@example.com")
      post :create, :email => email, :format => format
    end

    describe 'if the email is not valid' do

      describe 'if the request asks for html' do

        it 'should render the "new" template' do
          make_request(format="html", email="")
          response.should render_template("new")
        end

      end

      describe 'if the request asks for json' do

        it 'should return a json hash with the error keyed by "email"' do
          make_request(format="json", email="")
          JSON.parse(response.body)['errors'].should == {'email' => 'Please enter a valid email address'}
        end

        it 'should return a json hash with a success key set to false' do
          make_request(format="json", email="")
          JSON.parse(response.body)['success'].should == false
        end

      end

    end

    describe 'if the email is valid' do

      before do
        ActionConfirmation.stub!(:create!)
      end

      it 'should find the user by their email address' do
        User.should_receive(:find_by_email).with('test@example.com')
        make_request
      end

      describe 'if the user is found' do

        before do
          @user = mock_model(User, :reset_perishable_token! => true,
                                   :perishable_token => 'mytoken')
          User.stub!(:find_by_email).and_return(@user)
          ActionConfirmation.stub!(:create!)
          UserMailer.stub!(:deliver_password_reset_instructions)
        end

        it "it should reset the user's perishable token" do
          @user.should_receive(:reset_perishable_token!)
          make_request
        end

        it 'should deliver the password reset instructions' do
          UserMailer.should_receive(:deliver_password_reset_instructions).with(@user, nil, nil)
          make_request
        end

      end

      it 'should set the action to be confirmed to changing the password' do
        make_request
        assigns[:action].should == 'your password will not be changed.'
      end


      describe 'if the request asks for html' do

        it 'should render the "confirmation sent" template' do
          make_request
          response.should render_template('shared/confirmation_sent')
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

  end

  describe 'PUT #update' do

    def make_request(session_info = {})
      put :update, { :email_token => 'mytoken', 
                     :user => { :password => 'boo',
                                :password_confirmation => 'booagain' } }, session_info
    end

    it_should_behave_like "an action requiring an action confirmation token"

    describe 'if a user can be found with the action confirmation token' do

      before do
        @user = mock_model(User, :password= => true,
                                 :password_confirmation= => true,
                                 :registered? => true,
                                 :suspended? => false,
                                 :ignore_blank_passwords= => true,
                                 :save => true,
                                 :registered= => nil,
                                 :confirmed_password= => true, 
                                 :force_password_validation= => true)
        @mock_confirmation = mock_model(ActionConfirmation, :user => @user, :target => nil)
        ActionConfirmation.stub!(:find_by_token).with('mytoken', :include => :user).and_return(@mock_confirmation)
      end

      it 'should set the password and password confirmation on the user' do
        @user.should_receive(:password=).with('boo')
        @user.should_receive(:password_confirmation=).with('booagain')
        make_request
      end
      
      it 'should check to see if the user saves' do
        @user.should_receive(:save)
        make_request
      end

      describe 'if the user does not save' do

        before do
          @user.stub!(:save).and_return(false)
        end

        it 'should render the "edit" template' do
          make_request
          response.should render_template("edit")
        end

      end

      describe 'if the user saves' do

        before do
          @user.stub!(:save).and_return(true)
        end

        it 'should show a notice saying that the password has been updated' do
          make_request
          flash[:notice].should == 'Your password has been successfully updated.'
        end

        it 'should redirect back to the location the user was going when they were last asked to login if one was set' do
          session_info = { :return_to => campaigns_url }
          make_request session_info
          response.should redirect_to(campaigns_url)
        end

        it 'should redirect back to the root url if no redirect location has been set for the user' do
          make_request
          response.should redirect_to(root_url)
        end

        describe 'if the post-login action is to create a problem' do 
          
          before do 
            @problem = mock_model(Problem, :status => :new, 
                                           :created_at => (Time.now - 1.day))
            @mock_confirmation.stub!(:target).and_return(@problem)
          end
          
          it 'should show a notice saying that the password has been updated and that the user 
          now needs to decide if the problem should be public' do 
            make_request
            flash[:notice].should == "You've successfully reset your password. <strong>Decide if you want other people's support and we'll send your problem report on its way.</strong>"
          end
          
          it 'should redirect to the problem conversion URL' do 
            make_request
            response.should redirect_to(convert_problem_url(@problem))
          end
          
        end
        
      end

    end

  end

end