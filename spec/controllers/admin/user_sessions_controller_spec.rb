require 'spec_helper'

describe Admin::UserSessionsController do

  describe 'GET #new' do

    def make_request
      get :new
    end

    it 'should render the "new" template' do
      make_request
      response.should render_template("new")
    end

  end

  describe 'POST #create' do

    before do
      @default_params = { :admin_user_session => {:login => 'test@example.com',
                                                  :password => 'mypassword'} }
      @mock_user = mock_model(User, :suspended? => false,
                                    :is_admin? => true)
      @mock_admin_user = mock_model(AdminUser, :user => @mock_user)
      @admin_user_session = mock_model(AdminUserSession, :save => true,
                                              :destroy => true,
                                              :errors => mock('errors', :add  => nil),
                                              :record => @mock_admin_user,
                                              :id= => nil,
                                              :httponly= => nil,
                                              :secure= => nil)
      AdminUserSession.stub!(:new).and_return(@admin_user_session)
      controller.stub!(:current_user).and_return(@mock_user)
    end

    def make_request(params=@default_params)
      post :create, params
    end

    it 'should create a new admin user session with the login credentials' do
      AdminUserSession.should_receive(:new).with({'login' => 'test@example.com',
                                                  'password' => 'mypassword'})
      make_request
    end

    it 'should set an :admin id on the session to distinguish it from a regular session' do
      @admin_user_session.should_receive(:id=).with(:admin)
      make_request
    end

    it 'should set the session as secure (cookie setting)' do
      @admin_user_session.should_receive(:secure=).with(true)
      make_request
    end

    it 'should set the session as httponly (cookie setting)' do
      @admin_user_session.should_receive(:httponly=).with(true)
      make_request
    end

    it 'should try to save the user session' do
      @admin_user_session.should_receive(:save)
      make_request
    end

    describe 'if the session is not valid' do

      before do
        @admin_user_session.stub!(:save).and_return(false)
      end

      it 'should render the "new" template' do
        make_request
        response.should render_template("new")
      end

    end


    describe 'if the session is valid' do

      before do
        @admin_user_session.stub!(:save).and_return(true)
      end

      describe 'if the user is suspended' do

        before do
          @mock_user.stub!(:suspended?).and_return(true)
        end

        it 'should destroy the user session' do
          @admin_user_session.should_receive(:destroy)
          make_request
        end

        it 'should show an error message' do
          make_request
          flash[:error].should == 'Unable to authenticate &mdash; this account has been suspended.'
        end

        it 'should render the new template' do
          make_request
          response.should render_template('new')
        end

        it 'should not perform any redirect' do
          make_request(@default_params.update(:redirect => '/my_url'))
          response.should render_template("new")
        end

      end

      describe 'if the user is not suspended' do

        before do
          @mock_user.stub!(:suspended?).and_return(false)
        end

        it 'should redirect to the admin front page' do
          make_request
          response.should redirect_to(controller.admin_url(admin_root_path))
        end

        it 'should show a success notice' do
          make_request
          flash[:notice].should == 'Sign in successful!'
        end

        it 'should redirect to the admin url for a relative path passed in the redirect param' do
          make_request(@default_params.update(:redirect => '/my_url'))
          response.should redirect_to(controller.admin_url("/my_url"))
        end

      end

    end

  end

  describe 'GET #destroy' do


    def make_request
      get :destroy
    end

    describe 'when looking for a user session' do

      # This should be true for all admin actions, but is tested only here. Other admin actions have
      # current_user stubbed out from spec/spec_helper.rb
      it 'should look for a session with an id of :admin' do
        AdminUserSession.should_receive(:find).with(:admin)
        make_request
      end

    end

    describe 'if there is not a logged in user' do

      before do
        @mock_user = mock_model(User, :suspended? => false, :is_admin? => true)
        @admin_user_session = mock_model(AdminUserSession, :save => true, :destroy => true, :record => @mock_user)
        controller.stub!(:current_user).and_return(nil)
      end

      it 'should redirect to the admin login url' do
        make_request
        response.should redirect_to(controller.admin_url(admin_login_path))
      end

    end

    describe 'if there is a logged in user' do

      before do
        @mock_user = mock_model(User, :suspended? => false, :is_admin? => true)
        @admin_user_session = mock_model(AdminUserSession, :save => true, :destroy => true, :record => @mock_user)
        controller.stub!(:current_user).and_return(@mock_user)
        controller.stub!(:current_user_session).and_return(@admin_user_session)
      end

      it 'should destroy the user session' do
        @admin_user_session.should_receive(:destroy)
        make_request
      end

      it 'should show a successful login notice' do
        make_request
        flash[:notice].should == 'Sign out successful!'
      end

      it 'should redirect to the admin front page' do
        make_request
        response.should redirect_to(controller.admin_url(admin_root_path))
      end

    end

  end

end