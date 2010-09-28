require 'spec_helper'

describe CampaignsController do

  
  describe 'GET #index' do

    def make_request
      get :index
    end
    
    it 'should render the campaigns/index template' do 
      make_request
      response.should render_template("campaigns/index")
    end
    
    it 'should ask for campaigns' do 
      Campaign.should_receive(:find).and_return([])
      make_request
    end
  
  end
  
  describe 'GET #show' do 
  
    before do
      mock_assignment = mock_model(Assignment, :task_type_name => 'A test task')
      @campaign = mock_model(Campaign, :id => 8, 
                                       :title => 'A test campaign',
                                       :default_assignment => mock_assignment,
                                       :initiator_id => 44, 
                                       :location => mock_model(Stop, :points => [mock("point", :lat => 51, :lon => 0)]))
      Campaign.stub!(:find).and_return(@campaign)
    end
    
    def make_request
      get :show, :id => 8
    end
    
    it 'should ask for the campaign by id' do 
      Campaign.should_receive(:find).with('8').and_return(@campaign)
      make_request
    end
    
    it 'should not display a campaign that has not been confirmed' do 
      mock_confirmed_campaigns = mock("confirmed campaigns")
      Campaign.stub!(:confirmed).and_return(mock_confirmed_campaigns)
      mock_confirmed_campaigns.stub!(:find).and_return(nil)
      make_request
      response.status.should == '404 Not Found'
    end
    
  end
  
  shared_examples_for "an action that requires the campaign owner or a token" do 
        
    describe 'when the campaign is new' do

      before do 
        @mock_campaign.stub!(:status).and_return(:new)
      end
      
      describe 'and the campaign initiator is a registered user' do 
        
        before do 
          @campaign_user.stub!(:registered?).and_return(true)
        end
      
        describe "and the campaign's problem's token is not supplied" do        
          
          it 'should do the default behaviour for the action if the current user is the campaign initiator' do 
            controller.stub!(:current_user).and_return(@campaign_user)
            make_request
            response.should do_default_behaviour
          end
          
          it "should return a 'not found' response if the current user is not the campaign initiator" do 
            controller.stub!(:current_user).and_return(mock_model(User))
            make_request
            response.status.should == '404 Not Found'
          end
          
          it "should return a 'not found' response if there is no current user" do 
            controller.stub!(:current_user).and_return(nil)
            make_request
            response.status.should == '404 Not Found'            
          end
        
        end
   
        describe "and the campaign's problem's token is supplied" do 
          
          it 'should do the default behaviour for the action if the current user is the campaign initiator' do 
            controller.stub!(:current_user).and_return(@campaign_user)
            make_request(token=@mock_problem.token)
            response.should do_default_behaviour
          end
          
          it 'should redirect to the login page with a message if the current user is not the campaign initiator' do 
            controller.stub!(:current_user).and_return(mock_model(User))
            make_request(token=@mock_problem.token)
            response.should redirect_to(login_url)
            flash[:notice].should == "Login as Campaign User to confirm this campaign"
          end
          
          it 'should redirect to the login page with a message if there is no current user' do 
            controller.stub!(:current_user).and_return(nil)
            make_request(token=@mock_problem.token)
            response.should redirect_to(login_url)
            flash[:notice].should == "Login as Campaign User to confirm this campaign"          
          end
        
        end
    
      end
    
      describe 'and the campaign initiator is not yet a registered user' do 
        
        before do 
          @campaign_user.stub!(:registered?).and_return(false)
        end
    
        describe "and the campaign's problem's token is not supplied" do     

          it 'should return a "not found" response' do 
            make_request
            response.status.should == '404 Not Found' 
          end

        end
        
        describe "and the campaign's problem's token is supplied" do 
          
          it 'should do the default behaviour for the action if there is no current user' do 
            controller.stub!(:current_user).and_return(nil)
            make_request(token=@mock_problem.token)
            response.should do_default_behaviour
          end
          
          it 'should render the "wrong_user" template if there is a current user' do 
            controller.stub!(:current_user).and_return(mock_model(User))
            make_request(token=@mock_problem.token)
            response.should render_template("campaigns/wrong_user")
          end
          
        end
      
      end

    end
    
    describe 'when the campaign is confirmed' do 
      
      before do 
       @mock_campaign.stub!(:status).and_return(:confirmed)
      end
      
      describe 'and the current user is the campaign initiator' do 
      
        it 'should do the default behaviour of the action' do   
          controller.stub!(:current_user).and_return(@campaign_user)
          make_request
          response.should do_default_behaviour
        end
        
      end
      
      describe 'and the current user is not the campaign initiator' do
        
        it 'should redirect to the login page with a message' do 
          controller.stub!(:current_user).and_return(mock_model(User))
          make_request(token=@mock_problem.token)
          response.should redirect_to(login_url)
          flash[:notice].should == "Login as Campaign User to edit this campaign"
        end
        
      end
      
      describe 'and there is no current user' do 

        it 'should redirect to the login page with a message' do 
          controller.stub!(:current_user).and_return(nil)
          make_request(token=@mock_problem.token)
          response.should redirect_to(login_url)
          flash[:notice].should == "Login as Campaign User to edit this campaign"
        end

      end
    
    end
  end
  
  describe 'PUT #update' do 
    
    before do 
      @campaign_user = mock_model(User, :name => "Campaign User", 
                                        :save => true, 
                                        :registered? => false, 
                                        :attributes= => true, 
                                        :registered= => true)
      @mock_problem = mock_model(Problem, :token => 'problem-token')
      @mock_campaign = mock_model(Campaign, :problem => @mock_problem, 
                                            :initiator => @campaign_user, 
                                            :attributes= => true, 
                                            :valid? => true, 
                                            :confirmed= => true,
                                            :save => true, 
                                            :status => :new)
      Campaign.stub!(:find).and_return(@mock_campaign)
    end
    
    def make_request(token=nil)
      put :update, { :id => 33, :token => token, 
                                :campaign => { :title => 'Test Campaign' }, 
                                :user => { :password => 'A password' } }
    end   
    
    def do_default_behaviour
      redirect_to(campaign_url(@mock_campaign))
    end
    
    it_should_behave_like "an action that requires the campaign owner or a token"
    
    it 'should update the campaign with the campaign params passed' do 
      @mock_campaign.should_receive(:attributes=).with("title" => 'Test Campaign')
      make_request(token=@mock_problem.token)
    end
    
    describe 'if a valid token and user params are supplied' do 
      
      it 'should update the campaign initiator with the user params' do 
        @campaign_user.should_receive(:attributes=).with("password" => 'A password')
        make_request(token=@mock_problem.token)
      end
      
      it 'should set the registered flag on the user' do 
        @campaign_user.should_receive(:registered=).with(true)
        make_request(token=@mock_problem.token)
      end
      
      it 'should set the confirmed flag on the campaign' do
        @mock_campaign.should_receive(:confirmed=).with(true)
        make_request(token=@mock_problem.token)
      end
    
    end
    
    describe 'if the campaign is valid' do 
      
      before do 
        @mock_campaign.stub!(:valid?).and_return(true)
      end
      
      it 'should save the campaign' do 
        @mock_campaign.should_receive(:save)
        make_request(token=@mock_problem.token)
      end
      
      it 'should save the campaign initiator (logging them in though authlogic)' do
        @campaign_user.should_receive(:save)
        make_request(token=@mock_problem.token)
      end
      
      it 'should redirect to the campaign url' do 
        make_request(token=@mock_problem.token)
        response.should redirect_to(campaign_url(@mock_campaign))
      end
       
    end
    
    describe 'if the campaign is not valid' do 
      
      it 'should render the "edit" template' do 
        @mock_campaign.stub!(:valid?).and_return(false)
        make_request(token=@mock_problem.token)
        response.should render_template("campaigns/edit")
      end
      
    end
    
  end
  
  describe 'GET #edit' do 
    
    before do 
      @campaign_user = mock_model(User, :name => "Campaign User")
      @mock_problem = mock_model(Problem, :token => 'problem-token')
      @mock_campaign = mock_model(Campaign, :problem => @mock_problem, 
                                            :initiator => @campaign_user)
      Campaign.stub!(:find).and_return(@mock_campaign)
    end
    
    def make_request(token=nil)
      get :edit, { :id => 33, :token => token }
    end
    
    def do_default_behaviour
      render_template("campaigns/edit")
    end

    it_should_behave_like "an action that requires the campaign owner or a token"
    
  end

  describe 'GET #join' do 
    
    before do 
      Campaign.stub!(:find).and_return(mock_model(Campaign))
    end
    
    def make_request
      get :join, { :id => 44 }
    end
    
    it "should render the 'join' template" do 
      make_request
      response.should render_template("campaigns/join")
    end

  end
  
  describe 'POST #join' do
    
    before do 
      @mock_campaign = mock_model(Campaign, :supporters => [], 
                                            :title => 'A test title',
                                            :add_supporter => true)
      Campaign.stub!(:find).and_return(@mock_campaign)
    end
    
    def make_request(params)
      post :join, params
    end
    
    describe 'when the current user has the same user id as that passed in the params' do 
      
      before do 
        @user = mock_model(User, :id => 55)
        @controller.stub!(:current_user).and_return(@user)
      end
      
      it 'should make the user a confirmed campaign supporter' do
        @mock_campaign.should_receive(:add_supporter).with(@user, confirmed=true)
        make_request({ :id => 44, :user_id => '55' })
      end
      
      it 'should redirect them to the campaign URL' do 
        make_request({ :id => 44, :user_id => '55' })
        response.should redirect_to(campaign_url(@mock_campaign))
      end
    
    end
    
    describe 'when an invalid email address is supplied' do 
       
      it 'should render the "join" template' do 
        make_request({ :id => 44, :email => 'bad_email' })
        response.should render_template('join')
      end
    
    end
    
    describe 'when a valid email address is supplied' do 
    
      before do 
        @mock_user = mock_model(User, :valid? => true, :save_if_new => true)
        User.stub!(:find_or_initialize_by_email).and_return(@mock_user)
      end
      
      it 'should save the user if new' do 
        @mock_user.should_receive(:save_if_new)
        make_request({ :id => 44, :email => 'goodemail' })
      end
      
      it 'should make the user a campaign supporter' do 
        @mock_campaign.should_receive(:add_supporter).with(@mock_user, confirmed=false)
        make_request({ :id => 44, :email => 'goodemail' })
      end
      
      it 'should render the "confirmation_sent" template' do
        make_request({ :id => 44, :email => 'goodemail' })
        response.should render_template('shared/confirmation_sent')
      end
      
    end
  end
  
end
