require 'spec_helper'

describe OutgoingMessagesController do

  def mock_campaign
    @campaign_user = mock_model(User, :name => "Campaign User")
    @mock_outgoing_message = mock_model(OutgoingMessage, :save => true, 
                                                         :recipient => @mock_council_contact, 
                                                         :recipient= => true, 
                                                         :incoming_message= => true,
                                                         :assignment= => true,
                                                         :body= => true,
                                                         :send_message => true, 
                                                         :assignment => nil,
                                                         :campaign= => nil,
                                                         :author= => nil,
                                                         :incoming_message_or_recipient_or_assignment => true)
    @mock_campaign_event = mock_model(CampaignEvent)
    @outgoing_messages_mock = mock('outgoing message association', :build => @mock_outgoing_message)
    @campaign_events_mock = mock('campaign events association', :create! => @mock_campaign_event)
    @mock_campaign = mock_model(Campaign, :editable? => true,
                                          :visible? => true,
                                          :initiator => @campaign_user,
                                          :status => :confirmed,
                                          :outgoing_messages => @outgoing_messages_mock, 
                                          :campaign_events => @campaign_events_mock)
    @controller.stub!(:current_user).and_return(@campaign_user)
    Campaign.stub!(:find).and_return(@mock_campaign)
    OutgoingMessage.stub!(:new).and_return(@mock_outgoing_message)
  end
  
  describe "GET #new" do 
    
    before do 
      @default_params = { :campaign_id => 66, :recipient_id => 1, :recipient_type => 'CouncilContact' }
      mock_campaign
      CouncilContact.stub!(:find).and_return(mock_model(CouncilContact))
      @expected_access_message = :outgoing_messages_new_access_message
    end
    
    def make_request params
      get :new, params 
    end
        
    it 'should render the template "new"' do 
      make_request @default_params
      response.should render_template('new')
    end

    describe 'if the outgoing message does not have a recipient or an assignment or an incoming message' do 
    
      before do
        @mock_outgoing_message.stub!(:incoming_message_or_recipient_or_assignment).and_return(false)
      end
      
      it 'should redirect to the campaign page' do 
        make_request @default_params
        response.should redirect_to(campaign_url(@mock_campaign))
      end
      
    end
    
    it_should_behave_like "an action that requires the campaign initiator"
  
  end
  
  describe 'POST #create' do 
    
    before do 
      mock_campaign
      @default_params = { :campaign_id => 66 }
      @expected_access_message = :outgoing_messages_create_access_message
    end
    
    def make_request params
      post :create, params
    end
    
    it 'should create an outgoing message for the campaign' do 
      @outgoing_messages_mock.should_receive(:build).with({ 'text' => 'test text' }).and_return(@mock_outgoing_message)
      make_request({:campaign_id => 55, :outgoing_message => { :text => 'test text' }})
    end  
    
    describe 'if the outgoing message cannot be saved' do 
      
      it 'should render the "new" template' do 
        @mock_outgoing_message.stub!(:save).and_return(false)
        make_request(@default_params)
        response.should render_template('new')
      end
      
    end
  
    describe 'if the outgoing message can be saved' do 
    
      it 'should redirect to the outgoing message page' do
        @mock_outgoing_message.stub!(:save).and_return(true)
        make_request(@default_params)
        response.should redirect_to(campaign_outgoing_message_path(@mock_campaign, @mock_outgoing_message))
      end
      
      it 'should send the outgoing message' do 
        @mock_outgoing_message.stub!(:save).and_return(true)
        @mock_outgoing_message.should_receive(:send_message)
        make_request(@default_params)
      end
      
      describe 'if the outgoing message belongs to a complete assignment' do 
      
        before do 
          @mock_assignment = mock_model(Assignment, :status => :complete)
        end
        
        it 'should not complete the assignment' do 
          @mock_outgoing_message.stub!(:assignment).and_return(@mock_assignment)
          @mock_assignment.should_not_receive(:complete!)
          make_request(@default_params)
        end
        
      end
      
      describe 'if the outgoing message belongs to an assignment that is not complete' do 
      
        before do 
          @mock_assignment = mock_model(Assignment, :status => :new)
        end
        
        it 'should complete the assignment' do 
          @mock_outgoing_message.stub!(:assignment).and_return(@mock_assignment)
          @mock_assignment.should_receive(:complete!)
          make_request(@default_params)
        end
      
      end
    
    end
    
    it_should_behave_like "an action that requires the campaign initiator"    
  
  end
  
  describe 'GET #show' do 
    
    before do 
      @mock_outgoing_message = mock_model(OutgoingMessage)
      OutgoingMessage.stub!(:find).and_return(@mock_outgoing_message)
      @campaign = mock_model(Campaign, :visible? => true, 
                                       :editable? => true)
      @default_params = { :campaign_id => 55, :id => 33 }
    end
  
    def make_request(params=@default_params)
      get :show, params
    end
    
    it_should_behave_like "an action requiring a visible campaign"
    
    describe 'when there is a visible campaign' do
      
      before do 
        Campaign.stub!(:find).and_return(@campaign)
      end
    
      it 'should render the "show" template' do 
        make_request
        response.should render_template('show')
      end
    
      it 'should get the incoming message' do 
        OutgoingMessage.should_receive(:find).with('33')
        make_request
      end
      
    end
    
  end
  
end