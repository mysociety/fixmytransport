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
    
    describe 'when a post-login action of joining the campaign is passed' do
      
      before do 
        @next_action_data = @controller.send(:data_to_string, { :action => :join_campaign })
      end
  
      it 'should save the post-login action to the session' do 
        make_request(:next_action => @next_action_data)
        session[:next_action].should == @next_action_data
      end
    
      it 'should set a notice for the current action' do 
        make_request(:next_action => @next_action_data)
        response.flash[:notice].should == "Please login or create an account to join this campaign"
      end
    end
    
  end
  
  describe 'POST #create' do 
  
    def make_request(params={:format=>"html"})
      post :create, params
    end
    
    before do
      @controller.stub!(:current_user).and_return(nil)
      @user_session = mock_model(UserSession, :save => true)
      UserSession.stub!(:new).and_return(@user_session) 
    end
    
    it 'should save the post-login action to the session' do 
      @controller.should_receive(:save_post_login_action_to_session)
      make_request
    end
    
    describe 'if the user session is valid' do
    
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
          make_request(:next_action => @next_action_data)
        end
        
        it 'should return to the redirect given' do 
          make_request(:next_action => @next_action_data)
          response.should redirect_to("/another_url")
        end
        
        it 'should show a notice ' do
          make_request(:next_action => @next_action_data)
          flash[:notice].should == "Thanks for joining this campaign"
        end
      
      end
      
      describe 'if the request asks for json' do 
      
        it 'should return a json hash with a success key set to true' do 
          make_request({:format=>"json"})
          JSON.parse(response.body)['success'].should == true
        end
      
      end
      
    end
    
    describe 'if the user session is not valid' do 
      
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
          make_request({:format=>"json"})
          JSON.parse(response.body)['errors'].should == {'base' => 'Test error message'}
        end
        
        it 'should return a json hash with a success key set to false' do 
          make_request({:format=>"json"})
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
      User.should_receive(:handle_external_auth_token).with('mytoken', 'facebook')
      make_request
    end
    
    it 'should redirect to the path given in the path param' do 
      make_request
      response.should redirect_to("/my/path")
    end
    
  end

end
