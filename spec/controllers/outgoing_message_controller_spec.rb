require 'spec_helper'

describe OutgoingMessagesController do

  def mock_campaign
    @campaign_user = mock_model(User, :name => "Campaign User")
    @mock_council_contact = mock_model(CouncilContact)
    @mock_outgoing_message = mock_model(OutgoingMessage, :save => true, 
                                                         :recipient => @mock_council_contact, 
                                                         :send_message => true)
    @outgoing_messages_mock = mock('outgoing message association', :build => @mock_outgoing_message)
    @incoming_messages_mock = mock('incoming message association', :find => nil)
    @mock_campaign = mock_model(Campaign, :confirmed => true,
                                          :initiator => @campaign_user,
                                          :outgoing_messages => @outgoing_messages_mock,
                                          :incoming_messages => @incoming_messages_mock)
    @controller.stub!(:current_user).and_return(@campaign_user)
    Campaign.stub!(:find).and_return(@mock_campaign)
  end
  
  describe "GET #new" do 
    
    before do 
      @default_params = { :campaign_id => 66, :recipient_id => 1, :recipient_type => 'CouncilContact' }
      mock_campaign
      @expected_access_message = :outgoing_messages_new_access_message
    end
    
    def make_request params
      get :new, params 
    end
    
    it 'should render the template "new"' do 
      make_request @default_params
      response.should render_template('new')
    end
    
    describe 'if a recipient id and type are included in the params' do
    
      it 'should find the recipient' do
        CouncilContact.should_receive(:find).with("1") 
        make_request @default_params
      end
    
      it 'should set the recipient on the outgoing message' do 
        CouncilContact.stub!(:find).and_return(@mock_council_contact)
        @outgoing_messages_mock.should_receive(:build).with(hash_including({:recipient => @mock_council_contact}))
        make_request @default_params
      end
    
    end
    
    describe 'if an incoming message id is included in the params' do 
    
      before do 
        @mock_incoming_message = mock_model(IncomingMessage)
        @params = { :campaign_id => 66, :incoming_message_id => 22 }
      end
      
      it 'should find the incoming message associated with the campaign' do 
        @mock_campaign.incoming_messages.should_receive(:find).with("22")
        make_request(@params)
      end
      
      it 'should set the incoming message on the outgoing message' do 
        @mock_campaign.incoming_messages.stub!(:find).and_return(@mock_incoming_message)
        @outgoing_messages_mock.should_receive(:build).with(hash_including({:incoming_message => @mock_incoming_message}))       
        make_request(@params)        
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
      @outgoing_messages_mock.should_receive(:build).with({ 'text' => 'test text' })
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
    
    end
    
    it_should_behave_like "an action that requires the campaign initiator"    
  
  end
  
  describe 'GET #show' do 
    
    before do 
      @mock_outgoing_message = mock_model(OutgoingMessage)
      OutgoingMessage.stub!(:find).and_return(@mock_outgoing_message)
      @default_params = { :campaign_id => 55, :id => 33 }
    end
  
    def make_request params
      get :show, params
    end
    
    it 'should render the "show" template' do 
      make_request(@default_params)
      response.should render_template('show')
    end
    
    it 'should get the incoming message' do 
      OutgoingMessage.should_receive(:find).with('33')
      make_request(@default_params)
    end
    
  end
  
end