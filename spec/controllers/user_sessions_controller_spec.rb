require 'spec_helper'

describe UserSessionsController do

  describe 'GET #new' do
    
    def make_request
      get :new
    end
    
    it 'should not save the post-login action to the session' do 
      @controller.should_not_receive(:save_post_login_action_to_session)
      make_request
    end
    
  end

  describe 'POST #new' do 
    
    def make_request(params={})
      post :new, params
    end

    it 'should render the "new" template' do 
      make_request
      response.should render_template("new")
    end

  end
  
  describe 'POST #create' do 
  
  
    def make_request(params=@default_params)
      post :create, params
    end
    
    before do
      @controller.stub!(:current_user).and_return(nil)
      @mock_user = mock_model(User, :suspended? => false)
      @user_session = mock_model(UserSession, :save => true, :destroy => true, :record => @mock_user)
      UserSession.stub!(:new).and_return(@user_session) 
      @default_params = {:format=>"html", :user_session => {:login => 'test@example.com', 
                                                            :password => 'mypassword',
                                                            :login_by_password => true}}
    end
    
    it 'should save the post-login action to the session' do 
      @controller.should_receive(:save_post_login_action_to_session)
      make_request
    end
    
    it 'should set "login_by_password" on the params passed to the user session for validation' do 
      UserSession.should_receive(:new).with("login" => 'test@example.com', 
                                            "password" => 'mypassword', 
                                            "login_by_password" => true)
      make_request
    end
        
    describe 'if the user session is valid and the user has confirmed their password' do
    
      describe 'and a post-login action of joining a campaign is passed' do 

        before do 
          @mock_campaign = mock_model(Campaign, :add_supporter => true)
          Campaign.should_receive(:find).with(33).and_return(@mock_campaign)
          @next_action_data = @controller.send(:data_to_string, { :action => :join_campaign,
                                                                  :id => 33,
                                                                  :redirect => '/another_url'})
        end
        
        it 'should add the supporter to the campaign' do
          @mock_campaign.should_receive(:add_supporter)
          make_request(@default_params.update(:next_action => @next_action_data))
        end
        
        it 'should return to the redirect given' do 
          make_request(@default_params.update(:next_action => @next_action_data))
          response.should redirect_to("/another_url")
        end
      
      end
      
      describe 'if the request asks for json' do 
      
        it 'should return a json hash with a success key set to true' do 
          make_request(@default_params.update({:format=>"json"}))
          JSON.parse(response.body)['success'].should == true
        end
              
      end
      
      describe 'if the user is suspended' do
        
        before do
          @mock_user.stub!(:suspended?).and_return(true)
        end
        
        it 'should not create a user session and send an error message' do
          @user_session.should_receive(:destroy)
          make_request
          flash[:error].should == 'Unable to authenticate &mdash; this account has been suspended.'
        end

        it 'should disregard any redirects' do
          make_request(@default_params.update(:next_action => @next_action_data))
          response.should_not redirect_to("/another_url")
        end

        describe 'if the request asks for json' do 

          before do
            @mock_errors = [[:base, "error text"]]
            @user_session.stub!(:errors).and_return(@mock_errors)
            @controller.stub!(:add_json_errors).and_return()
          end
          
          it 'should return a json hash with failure and base error message' do
            @mock_errors.should_receive(:add_to_base).with("Unable to authenticate &mdash; this account has been suspended.") 
            make_request(@default_params.update({:format=>"json"}))
            JSON.parse(response.body)['success'].should == false
          end

        end

      end
      
    end
    
    describe 'if the user session is not valid or the user has not confirmed their password' do 
      
      before do
        @user_session.stub!(:save).and_return(false)
        @user_session.stub!(:errors).and_return([[:base, "Test error message"]])
      end
    
      describe 'if the request asks for html' do
        
        it 'should render the "new" template' do
          make_request
          response.should render_template("new")
        end
        
      end
      
      describe 'if the request asks for json' do 
      
        it 'should return a json hash with a key for errors' do 
          make_request(@default_params.update({:format=>"json"}))
          JSON.parse(response.body)['errors'].should == {'base' => 'Test error message'}
        end
        
        it 'should return a json hash with a success key set to false' do 
          make_request(@default_params.update({:format=>"json"}))
          JSON.parse(response.body)['success'].should == false
        end
        
      end
      
    end
    
  end

  describe "POST #external" do
  
    def make_request
      post :external, { :access_token => 'mytoken', 
                        :expiry => '12', 
                        :source => 'facebook', 
                        :path => '/my/path' }
    end
    
    before do 
      User.stub!(:handle_external_auth_token).and_return(true)
    end
    
    it 'should ask the user to handle an external auth token, passing the access token and source' do 
      User.should_receive(:handle_external_auth_token).with('mytoken', 'facebook', false)
      make_request
    end
    
    it 'should redirect to the path given in the path param' do 
      make_request
      response.should redirect_to("/my/path")
    end
    
  end

end
