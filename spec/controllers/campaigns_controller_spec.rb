require 'spec_helper'

describe CampaignsController do

  describe 'GET #add_details' do 
  
    before do 
      @default_params = {:id => 55}
      @mock_user = mock_model(User, :name => 'Test User')
      @mock_campaign = mock_model(Campaign, :editable? => true, 
                                            :visible? => false,
                                            :initiator => @mock_user)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @controller.stub!(:current_user).and_return(@mock_user)
    end
    
    def make_request(params=@default_params)
      get :add_details, params
    end
    
    describe 'if the campaign is not new' do 
      
      before do 
        @mock_campaign.stub!(:status).and_return(:confirmed)
      end
    
      it 'should redirect to the campaign URL' do
        make_request()
        response.should redirect_to(campaign_url(@mock_campaign))
      end
      
    end
    
    describe 'if the campaign is new' do
    
      before do
        @mock_campaign.stub!(:status).and_return(:new)
      end
      
      it 'should render the template "add_details"' do
        make_request()
        response.should render_template("add_details")
      end
    
    end
  
  end
  
  describe 'POST #add_details' do 
  
    before do 
      @mock_user = mock_model(User, :name => "Test User")
      @default_params = {:id => 55, :campaign => {:title => 'title', :description => 'description'}}
      @mock_campaign = mock_model(Campaign, :editable? => true, 
                                            :visible? => false,
                                            :update_attributes => true, 
                                            :initiator => @mock_user,
                                            :confirm => true,
                                            :save! => true)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @controller.stub!(:current_user).and_return(@mock_user)
    end
    
    def make_request(params=@default_params)
      post :add_details, params
    end
    
    describe 'if the campaign is not new' do 
      
      before do 
        @mock_campaign.stub!(:status).and_return(:confirmed)
      end
    
      it 'should redirect to the campaign URL' do
        make_request()
        response.should redirect_to(campaign_url(@mock_campaign))
      end
      
    end
    
    describe 'if the campaign is new' do
      
      before do 
        @mock_campaign.stub!(:status).and_return(:new)
      end
      
      it 'should try to update the campaign attributes' do 
        @mock_campaign.should_receive(:update_attributes).with({'title' => 'title', 'description' => 'description'})
        make_request
      end
      
      describe 'if the attributes can be updated' do 
      
        before do 
          @mock_campaign.stub!(:update_attributes).and_return(true)
        end
      
        it 'should save the campaign' do 
          @mock_campaign.should_receive(:save!)
          make_request
        end
        
        it 'should confirm the campaign' do 
          @mock_campaign.should_receive(:confirm)
          make_request
        end
        
        it 'should redirect to the share campaign url' do 
          make_request
          response.should redirect_to share_campaign_url(@mock_campaign)
        end
        
      end
      
      describe 'if the attributes cannot be updated' do 
      
        before do 
          @mock_campaign.stub!(:update_attributes).and_return(false)
        end
        
        it 'should render the template "add_details"' do 
          make_request
          response.should render_template("add_details")
        end
      
      end
      
    end
    
  end

  describe 'GET #show' do

    before do
      mock_assignment = mock_model(Assignment, :task_type_name => 'A test task')
      @campaign = mock_model(Campaign, :id => 8,
                                       :title => 'A test campaign',
                                       :initiator_id => 44,
                                       :editable? => true,
                                       :visible? => true,
                                       :campaign_photos => mock('campaign photos', :build => true),
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

    it 'should display a campaign that has been successful' do
      @campaign.stub!(:visible?).and_return(true)
      make_request
      response.status.should == '200 OK'
    end

    it_should_behave_like "an action requiring a visible campaign"

  end

  describe 'PUT #update' do

    before do
      @expert_user = mock_model(User, :is_expert? => true)
      @campaign_user = mock_model(User, :name => "Campaign User",
                                        :save => true,
                                        :is_expert? => false)
      @mock_problem = mock_model(Problem, :token => 'problem-token')
      @mock_campaign = mock_model(Campaign, :problem => @mock_problem,
                                            :initiator => @campaign_user,
                                            :attributes= => true,
                                            :editable? => true,
                                            :visible? => true,
                                            :status => :confirmed,
                                            :save => true)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @controller.stub!(:current_user).and_return(@campaign_user)
      @expected_wrong_user_message = "edit this campaign"
      @expected_new_access_message = :campaigns_edit_access_message
      @expected_access_message = :campaigns_update_access_message
      @default_params = { :id => 33, :campaign => { :description => 'Some stuff' }}
    end

    def make_request(params=@default_params)
      put :update, params
    end

    def do_default_behaviour
      redirect_to(campaign_url(@mock_campaign))
    end

    it_should_behave_like "an action that requires the campaign initiator"

    it 'should update the campaign with the campaign params passed' do
      @mock_campaign.should_receive(:attributes=).with("description" => 'Some stuff')
      make_request()
    end
    
    describe 'when the current user is an expert' do 
      
      it 'should do the default behaviour of the action' do
        controller.stub!(:current_user).and_return(@expert_user)
        make_request @default_params
        response.should do_default_behaviour
      end
       
    end

    describe 'if the campaign can be saved' do

      before do
        @mock_campaign.stub!(:save).and_return(true)
      end

      it 'should redirect to the campaign url' do
        make_request()
        response.should redirect_to(campaign_url(@mock_campaign))
      end
      
    end

    describe 'if the campaign cannot be saved' do

      before do 
        @mock_campaign.stub!(:save).and_return(false)
      end
      
      it 'should render the "edit" template' do
        make_request()
        response.should render_template("campaigns/edit")
      end

    end

  end

  describe 'GET #edit' do

    before do
      @expert_user = mock_model(User, :is_expert? => true)
      @campaign_user = mock_model(User, :name => "Campaign User", :is_expert? => false)
      @mock_problem = mock_model(Problem, :token => 'problem-token')
      @mock_campaign = mock_model(Campaign, :problem => @mock_problem,
                                            :initiator => @campaign_user,
                                            :title => 'A test campaign',
                                            :editable? => true,
                                            :visible? => true,
                                            :status => :confirmed,
                                            :description => 'Campaign description')
      Campaign.stub!(:find).and_return(@mock_campaign)
      @expected_wrong_user_message = "confirm this problem"
      @expected_new_access_message = :campaigns_edit_access_message
      @expected_access_message = :campaigns_edit_access_message
      @controller.stub!(:current_user).and_return(@campaign_user)
    end

    def make_request(token=nil)
      get :edit, { :id => 33, :token => token }
    end

    def do_default_behaviour
      render_template("campaigns/edit")
    end

    it_should_behave_like "an action that requires the campaign initiator"
    
    describe 'when the current user is an expert' do 
      
      it 'should do the default behaviour of the action' do
        controller.stub!(:current_user).and_return(@expert_user)
        make_request @default_params
        response.should do_default_behaviour
      end
       
    end 
  
  end

  describe 'GET #join' do

    before do
      Campaign.stub!(:find).and_return(mock_model(Campaign, :visible? => true, :editable? => true))
    end

    def make_request
      get :join, { :id => 44 }
    end

    it "should render the 'join' template" do
      make_request
      response.should render_template("campaigns/join")
    end

  end

  describe 'GET #add_update' do

    before do
      @campaign_user = mock_model(User, :name => "Campaign User")
      @mock_campaign = mock_model(Campaign, :visible? => true,
                                            :editable? => true,
                                            :initiator => @campaign_user,
                                            :status => :confirmed,
                                            :campaign_updates => mock('update', :build => true))
      Campaign.stub!(:find).and_return(@mock_campaign)
      @controller.stub!(:current_user).and_return(@campaign_user)
      @expected_wrong_user_message = "add an update"
      @expected_access_message = :campaigns_add_update_access_message
      @default_params = { :id => 55, :update_id => '33' }
    end

    def make_request params
      get :add_update, params
    end

    it 'should assign a campaign update to the view' do
      make_request({:id => 55})
      assigns[:campaign_update].should_not be_nil
    end

    it_should_behave_like "an action that requires the campaign initiator"
  end

  describe 'GET #add_comment' do

    before do
      @mock_campaign = mock_model(Campaign, :visible? => true, :editable? => true)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @mock_user = mock_model(User)
      @controller.stub!(:current_user).and_return(@mock_user)
    end

    def make_request(params=nil)
      params = { :id => 55 } if !params
      get :add_comment, params
    end

    it 'should render the template "add_comment"' do
      make_request
      response.should render_template('shared/add_comment')
    end

  end


  describe 'POST #add_comment' do

    before do
      @mock_user = mock_model(User)
      @mock_campaign = mock_model(Campaign, :visible? => true, 
                                            :editable? => true)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @mock_comment = mock_model(Comment, :save => true,
                                          :valid? => true,
                                          :user= => true,
                                          :commented_id => 55,
                                          :commented_type => 'Campaign',
                                          :commented => @mock_campaign,
                                          :text => 'comment text',
                                          :confirm! => true,
                                          :skip_name_validation= => true,
                                          :campaign_events => [],
                                          :status= => true)
      @mock_campaign.stub!(:comments).and_return(mock('comments', :build => @mock_comment))
      @expected_notice = "Please login or signup to add your comment to this campaign"
      @expected_redirect = campaign_url(@mock_campaign)
    end

    def make_request params
      post :add_comment, params
    end

    def default_params
      { :id => 55,
        :comment => { :commentable_id => 55,
                      :commentable_type => 'Campaign'} }
    end
    
    it_should_behave_like "an action that receives a POSTed comment"

  end
  
  describe 'POST #complete' do 
    
    before do 
      @user = mock_model(User, :id => 55, :name => "Test User")
      @default_params = { :id => 55 }
      @controller.stub!(:current_user).and_return(@user)
      @mock_campaign = mock_model(Campaign, :visible? => true,
                                            :editable? => true,
                                            :status => :confirmed,
                                            :initiator => @user, 
                                            :status= => true,
                                            :save => true)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @expected_access_message = :campaigns_complete_access_message
    end
  
    def make_request(params)
      post :complete, params
    end
    
    it_should_behave_like "an action that requires the campaign initiator"
    
    it 'should set the campaign status to complete and save it' do 
      @mock_campaign.should_receive(:status=).with(:successful)
      @mock_campaign.should_receive(:save)
      make_request(@default_params)
    end
    
    it 'should redirect to the campaign page' do 
      make_request(@default_params)
      response.should redirect_to(campaign_url(@mock_campaign))
    end
  
  end
  
  describe 'GET #add_photos' do 
    
    before do 
      @user = mock_model(User, :id => 55, :name => "Test User")
      @default_params = { :id => 55 }
      @controller.stub!(:current_user).and_return(@user)
      @mock_campaign = mock_model(Campaign, :visible? => true,
                                            :editable? => true,
                                            :status => :confirmed,
                                            :initiator => @user, 
                                            :campaign_photos => [])
      @mock_campaign.campaign_photos.stub!(:build).and_return(true)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @expected_access_message = :campaigns_add_photos_access_message
    end
    
    def make_request(params)
      get :add_photos, params
    end

    it_should_behave_like "an action that requires the campaign initiator"

    it 'should render the "add_photos" template' do
      make_request(@default_params)
      response.should render_template("add_photos")
    end
    
    it 'should build a new campaign photo associated with the campaign' do 
      @mock_campaign.campaign_photos.should_receive(:build).with({})
      make_request(@default_params)
    end
    
  end
  
  describe 'POST #add_photos' do 
    
    before do 
      @user = mock_model(User, :id => 55, :name => "Test User")
      @default_params = { :id => 55 }
      @controller.stub!(:current_user).and_return(@user)
      @mock_campaign = mock_model(Campaign, :visible? => true,
                                            :editable? => true,
                                            :status => :confirmed,
                                            :initiator => @user)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @expected_access_message = :campaigns_add_photos_access_message
    end
    
    def make_request(params)
      post :add_photos, params
    end

    it_should_behave_like "an action that requires the campaign initiator"
    
    describe 'if the campaign (with associated photo) can be saved' do 

      before do
        @mock_campaign.stub!(:update_attributes).and_return(true)
      end
            
      it 'should redirect to the campaign url' do 
        make_request(@default_params)
        response.should redirect_to(campaign_url(@mock_campaign))
      end
      
    end
    
    describe 'if the campaign (with associated photo) cannot be saved' do 
      
      before do
        @mock_campaign.stub!(:update_attributes).and_return(false)
      end
      
      it 'should render the add_photos template' do 
        make_request(@default_params)
        response.should render_template("add_photos")
      end
    
    end
  end

  describe 'POST #add_update' do

    before do
      @user = mock_model(User, :id => 55, :name => 'Test User')
      @controller.stub!(:current_user).and_return(@user)
      @mock_update = mock_model(CampaignUpdate, :save => true,
                                                :is_advice_request? => false,
                                                :user= => true)
      @mock_updates = mock('campaign updates', :build => @mock_update)
      @mock_events = mock('campaign events', :create! => true)
      @mock_campaign = mock_model(Campaign, :supporters => [],
                                            :title => 'A test title',
                                            :visible? => true,
                                            :editable? => true,
                                            :add_supporter => true,
                                            :status => :confirmed,
                                            :campaign_updates => @mock_updates,
                                            :campaign_events => @mock_events,
                                            :initiator => @user)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @expected_wrong_user_message = 'Add an update'
      @expected_access_message = :campaigns_add_update_access_message
      @default_params = { :id => 55, :update_id => '33' }
    end

    def make_request(params)
      post :add_update, params
    end

    it_should_behave_like "an action that requires the campaign initiator"

    it 'should redirect to the campaign url' do
      make_request(:id => 55)
      response.should redirect_to(campaign_url(@mock_campaign))
    end

    it 'should try and save the new campaign update' do
      @mock_updates.should_receive(:build).and_return(@mock_update)
      @mock_update.should_receive(:save).and_return(true)
      make_request(:id => 55)
    end

    describe 'if the update was successfully saved' do

      before do
        @mock_update.stub!(:save).and_return(true)
      end

      it 'should display a notice' do
        make_request(:id => 55)
        flash[:notice].should == 'Your update has been added.'
      end

      it "should add a 'campaign_update_added' event" do
        @mock_events.should_receive(:create!).with(:event_type => 'campaign_update_added',
                                                   :described => @mock_update)
        make_request(:id => 55)
      end

    end

    describe 'when handling JSON request' do

      it 'should return a json hash with a key "html"' do
        post :add_update, {:id => 55, :format => 'json'}
        json_hash = JSON.parse(response.body)
        json_hash['html'].should_not be_nil
      end
      
    end

  end

  describe 'POST #join' do

    before do
      @mock_campaign = mock_model(Campaign, :supporters => [],
                                            :title => 'A test title',
                                            :visible? => true,
                                            :editable? => true,
                                            :add_supporter => true)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @default_params = { :id => 44, :user_id => '55' }
    end

    def make_request(params=@default_params)
      post :join, params
    end

    describe 'when there is a current user' do

      before do
        @user = mock_model(User, :id => 55)
        @controller.stub!(:current_user).and_return(@user)
      end

      it 'should make the user a confirmed campaign supporter' do
        @mock_campaign.should_receive(:add_supporter).with(@user, confirmed=true)
        make_request(@default_params)
      end

      it 'should redirect them to the campaign URL' do
        make_request(@default_params)
        response.should redirect_to(campaign_url(@mock_campaign))
      end

    end

    describe 'when there is no current user' do 
      
      it 'should store the next action in the session' do 
        @controller.should_receive(:data_to_string)
        make_request
      end
      
      
      describe 'if the request asks for json' do 
        
        it 'should return a hash with the success key set to true' do 
        make_request(@default_params.update(:format => 'json'))
        json_hash = JSON.parse(response.body)
        json_hash['success'].should == true
        end
        
        it 'should return a hash with the "requires login" flag set to true' do 
          make_request(@default_params.update(:format => 'json'))
          json_hash = JSON.parse(response.body)
          json_hash['requires_login'].should == true
        end
        
        it 'should return a hash with a notice key giving a notice to show to the user' do 
          make_request(@default_params.update(:format => 'json'))
          json_hash = JSON.parse(response.body)
          json_hash['notice'].should == 'Please login or signup to join this campaign'
        end
      
      end
  
      describe 'if the request asks for html' do 
        
        it 'should redirect to the login page' do 
          make_request(@default_params)
          response.should redirect_to(login_url)
        end
        
        it 'should display a notice that the user needs to login to join the campaign' do
          make_request(@default_params)
          flash[:notice].should == 'Please login or signup to join this campaign'
        end
        
      end
      
    end
  
  end

  describe 'GET #confirm_join' do

    before do
      @mock_user = mock_model(User)
      @mock_supporter = mock_model(CampaignSupporter, :supporter => @mock_user,
                                                      :confirm! => true)
      CampaignSupporter.stub!(:find_by_token).and_return(@mock_supporter)
    end

    def make_request
      get :confirm_join, { :email_token => 'mytoken' }
    end

    it 'should assign an error to the view if the campaign supporter cannot be found' do
      CampaignSupporter.stub!(:find_by_token).and_return(nil)
      make_request
      assigns[:error].should == :error_on_join
    end

    it 'should assign the user to the view' do
      make_request
      assigns[:user].should == @mock_user
    end

    it 'should confirm the campaign supporter' do
      @mock_supporter.should_receive(:confirm!)
      make_request
    end

  end

  describe '#PUT confirm_join' do

    before do
      @mock_user = mock_model(User,  :attributes= => true,
                                     :registered= => true,
                                     :confirmed_password= => true,
                                     :name= => true,
                                     :password= => true,
                                     :password_confirmation= => true,
                                     :save => true)
      @mock_campaign = mock_model(Campaign)
      @mock_supporter = mock_model(CampaignSupporter, :supporter => @mock_user,
                                                      :confirm! => true,
                                                      :campaign => @mock_campaign)
      CampaignSupporter.stub!(:find_by_token).and_return(@mock_supporter)
    end

    def make_request
      put :confirm_join, { :email_token => 'mytoken', :user => {} }
    end

    it 'should assign an error to the view if the campaign supporter cannot be found' do
      CampaignSupporter.stub!(:find_by_token).and_return(nil)
      make_request
      assigns[:error].should == :error_on_register
    end

    it 'should assign the user to the view' do
      make_request
      assigns[:user].should == @mock_user
    end

    it 'should redirect to the campaign url if the user model can be saved' do
      make_request
      response.should redirect_to(campaign_url(@mock_campaign))
    end

    it 'should not redirect to the campaign url if the user model cannot be saved' do
      @mock_user.stub!(:save).and_return(false)
      make_request
      response.should_not redirect_to(campaign_url(@mock_campaign))
    end

  end

end
