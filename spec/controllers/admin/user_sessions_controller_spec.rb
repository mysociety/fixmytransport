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
      @default_params = { :user_session => {:login => 'test@example.com', 
                                            :password => 'mypassword'} }
      @mock_user = mock_model(User, :suspended? => false)
      @user_session = mock_model(UserSession, :save => true, :destroy => true, :record => @mock_user)
      UserSession.stub!(:new).and_return(@user_session) 
    end
    
    def make_request(params=@default_params)
      post :create, params
    end
    
    it 'should set :login_by_password on the params passed to the user session for validation' do 
      UserSession.should_receive(:new).with("login" => 'test@example.com', 
                                            "password" => 'mypassword', 
                                            "login_by_password" => true)
      make_request
    end
    
    it 'should try to save the user session' do 
      @user_session.should_receive(:save)
      make_request
    end
    
    describe 'if the session is not valid' do 
      
      before do 
        @user_session.stub!(:save).and_return(false)
      end
      
      it 'should render the "new" template' do 
        make_request
        response.should render_template("new")
      end
      
    end
    
    describe 'if the session is valid' do 
      
      before do 
        @user_session.stub!(:save).and_return(true)
      end
    
      describe 'if the user is suspended' do 
      
        before do 
          @mock_user.stub!(:suspended?).and_return(true)
        end
      
        it 'should destroy the user session' do 
          @user_session.should_receive(:destroy)
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
        
        it 'should redirect to a relative path passed in the redirect param' do 
          make_request(@default_params.update(:redirect => '/my_url'))
          response.should redirect_to("/my_url")
        end
        
      end
      
    end
    
  end

  describe 'GET #destroy' do 
    
    before do
      @mock_user = mock_model(User, :suspended? => false)
      @user_session = mock_model(UserSession, :save => true, :destroy => true, :record => @mock_user)
      controller.stub!(:current_user_session).and_return(@user_session) 
    end
    
    def make_request
      get :destroy
    end
    
    describe 'if there is not a logged in user' do 
      
      before do 
        controller.stub!(:current_user).and_return(nil)
      end
      
      it 'should redirect to the admin login url' do
        make_request
        response.should redirect_to(controller.admin_url(admin_login_path))
      end
      
    end

    describe 'if there is a logged in user' do 
      
      it 'should destroy the user session' do 
        @user_session.should_receive(:destroy)
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