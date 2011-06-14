require 'spec_helper'

describe Admin::IncomingMessagesController do

  describe 'DELETE #destroy' do
    
    before do
      @mock_events = mock('campaign events', :create! => true)
      @mock_campaign = mock_model(Campaign, :campaign_events => @mock_events)
      @incoming_message = mock_model(IncomingMessage, :campaign => @mock_campaign,
                                                      :destroy => true)
      IncomingMessage.stub!(:find).and_return(@incoming_message)
    end
    
    def make_request
      delete :destroy, {:id => 55 }
    end
    
    it 'should destroy the incoming message' do  
      @incoming_message.should_receive(:destroy)
      make_request
    end
    
    describe 'if the incoming message belongs to a campaign' do
    
      it 'should add an "incoming_message_deleted" campaign event to the campaign' do 
        @mock_events.should_receive(:create!).with({ :event_type => 'incoming_message_deleted', 
                                                     :data => anything })
        make_request
      end
       
      it 'should redirect to the campaign page' do 
        make_request
        response.should redirect_to(controller.admin_url(admin_campaign_path(@mock_campaign)))
      end
    
    end
    
    describe 'if the incoming message does not belong to a campaign' do 
    
      before do 
        @incoming_message.stub!(:campaign).and_return(nil)
      end
      
      it 'should redirect to the admin home page' do 
        make_request
        response.should redirect_to(controller.admin_url(admin_root_path))
      end
      
    end
    
  end 

  describe 'POST #redeliver' do 
    
    def make_request
      post :redeliver, { :campaign_id => 77,
                         :id => 66 }
    end
    
    before do 
      @mock_user = mock_model(User)
      @mock_old_events = mock('old campaign events', :create! => true)
      @old_campaign = mock_model(Campaign, :campaign_events => @mock_old_events)
      @mock_events = mock('campaign events', :create! => true)
      @destination_campaign = mock_model(Campaign, :campaign_events => @mock_events,
                                                   :get_recipient => @mock_user)
      @incoming_message = mock_model(IncomingMessage, :campaign => nil,
                                                      :update_attribute => true,
                                                      :from => 'test@example.com')
      Campaign.stub!(:find).and_return(@destination_campaign)
      IncomingMessage.stub!(:find).and_return(@incoming_message)
      CampaignMailer.stub!(:deliver_new_message)
    end
    
    it 'should look for the destination campaign identified by the campaign id param' do 
      Campaign.should_receive(:find).with('77').and_return(@destination_campaign)
      make_request
    end
    
    describe 'if the campaign cannot be found' do 
    
      before do 
        Campaign.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      end
      
      it 'should show an error' do 
        make_request
        flash[:error].should == "Failed to find destination campaign '77'"
      end
      
      it 'should redirect to the incoming message admin page' do 
        make_request
        response.should redirect_to(controller.admin_url(admin_incoming_message_path(@incoming_message)))
      end
      
    end
    
    describe 'if the campaign can be found' do 
      
      it 'should set the incoming message campaign to the destination campaign' do 
        @incoming_message.should_receive(:update_attribute).with('campaign_id', @destination_campaign.id)
        make_request
      end
      
      it 'should add an "incoming_message_received" campaign event to the destination campaign' do 
        @mock_events.should_receive(:create!).with({ :event_type => 'incoming_message_received', 
                                                     :described => @incoming_message })
        make_request
      end
      
      it 'should send a message to the recipient saying that there is a new email for them' do 
        CampaignMailer.should_receive(:deliver_new_message).with(@mock_user, @incoming_message, @destination_campaign)
        make_request
      end
      
      it 'should show a notice saying the campaign has been moved' do
        make_request
        flash[:notice].should == 'Incoming message has been moved to this campaign.'
      end
      
      it 'should redirect to the destination campaign admin page' do 
        make_request
        response.should redirect_to(controller.admin_url(admin_campaign_path(@destination_campaign)))
      end
    
      describe 'if the incoming message has an old campaign' do 
      
        before do 
          @incoming_message.stub!(:campaign).and_return(@old_campaign)
        end
        
        it 'should add an "incoming_message_redelivered" campaign event to the old campaign' do 
          @mock_old_events.should_receive(:create!).with(:event_type => 'incoming_message_redelivered', 
                                                         :described => @incoming_message, 
                                                         :data => anything)
          make_request
        end
        
      end
      
    end
    
  end
  
end