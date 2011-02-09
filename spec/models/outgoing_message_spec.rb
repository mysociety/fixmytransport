require 'spec_helper'

describe OutgoingMessage do 
  
  describe 'when validating' do 
  
    before do 
      @campaign = mock_model(Campaign, :existing_recipients => [],
                                       :incoming_messages => [])
      @outgoing_message = OutgoingMessage.new(:campaign => @campaign)
    end
    
    it 'should be invalid if there is a recipient who is not in the existing recipients for the campaign' do 
      expected_message = "Sorry, there's been an error creating your message. Please use the feedback form to let us know what happened."
      @outgoing_message.recipient = CouncilContact.new
      @outgoing_message.valid?.should be_false
      @outgoing_message.errors.on(:recipient).should == expected_message
    end
    
    it 'should be invalid if there is an incoming message that does not belong to the campaign' do 
      expected_message = "Sorry, there's been an error creating your message. Please use the feedback form to let us know what happened."
      @outgoing_message.incoming_message = IncomingMessage.new
      @outgoing_message.valid?.should be_false
      @outgoing_message.errors.on(:incoming_message).should == expected_message
    end
    
    it 'should be invalid if there is no incoming message, recipient or assignment' do 
      
    end
  
  end

  describe 'when sending a message' do
  
    before do
      @mock_campaign_events = mock('campaign events', :create! => true)
      @mock_campaign = mock_model(Campaign, :campaign_events => @mock_campaign_events)
      @outgoing_message = OutgoingMessage.new(:campaign => @mock_campaign)
      CampaignMailer.stub!(:deliver_outgoing_message)
      @outgoing_message.stub!(:save!)
    end
    
    it 'should deliver the message' do
      CampaignMailer.should_receive(:deliver_outgoing_message)
      @outgoing_message.send_message
    end
    
    it 'should create an "outgoing_message_sent" campaign event' do
      @mock_campaign_events.should_receive(:create!).with(:event_type => 'outgoing_message_sent', 
                                                          :described => @outgoing_message)
      @outgoing_message.send_message
    end
    
    it 'should save the message' do 
      @outgoing_message.should_receive(:save!)
      @outgoing_message.send_message
    end
    
  end

  describe 'when creating a message from attributes' do 
    
    before do
      @assignments_mock = mock('assignments association', :find => nil)
      @incoming_messages_mock = mock('incoming message association', :find => nil)
      @mock_campaign = mock_model(Campaign, :incoming_messages => @incoming_messages_mock,
                                            :assignments => @assignments_mock)
      @mock_user = mock_model(User)
    end
    
    describe 'if a recipient id and type are included in the attributes' do
    
      before do 
        @mock_council_contact = mock_model(CouncilContact)
        @attributes = { :recipient_type => 'CouncilContact', 
                        :recipient_id => '1' }
      end
      
      it 'should find the recipient' do
        CouncilContact.should_receive(:find).with("1") 
        OutgoingMessage.message_from_attributes(@mock_campaign, @mock_user, @attributes)
      end
    
      it 'should set the recipient on the outgoing message' do 
        CouncilContact.stub!(:find).and_return(@mock_council_contact)
        outgoing_message = OutgoingMessage.message_from_attributes(@mock_campaign, @mock_user, @attributes)
        outgoing_message.recipient.should == @mock_council_contact
      end
    
    end
    
    describe 'if an incoming message id is included in the attributes' do 
    
      before do 
        @mock_incoming_message = mock_model(IncomingMessage, :body_for_quoting => "hello",
                                                             :subject => "Something interesting")
        @attributes = { :incoming_message_id => 22 }
        @mock_campaign.incoming_messages.stub!(:find).and_return(@mock_incoming_message)
      end
      
      it 'should find the incoming message associated with the campaign' do 
        @mock_campaign.incoming_messages.should_receive(:find).with(22)
        outgoing_message = OutgoingMessage.message_from_attributes(@mock_campaign, @mock_user, @attributes)
      end
      
      it 'should set the incoming message on the outgoing message' do 
        outgoing_message = OutgoingMessage.message_from_attributes(@mock_campaign, @mock_user, @attributes)
        outgoing_message.incoming_message.should == @mock_incoming_message 
      end
      
      it 'should set the body as the quoted incoming message content' do 
        outgoing_message = OutgoingMessage.message_from_attributes(@mock_campaign, @mock_user, @attributes)
        outgoing_message.body.should == "\n\n-----Original Message-----\n\nhello\n"
      end
      
      it 'should set the subject as a reference to the incoming message subject' do
        outgoing_message = OutgoingMessage.message_from_attributes(@mock_campaign, @mock_user, @attributes)
        outgoing_message.subject.should == "Re: Something interesting"
      end
      
    end
  
    describe 'if an assignment id is included in the attributes' do 
    
      before do 
        @mock_assignment = mock_model(Assignment, :data => { :draft_text => 'hi' })
        @attributes = { :assignment_id => 77 }
        @mock_campaign.assignments.stub!(:find).and_return(@mock_assignment)
      end
      
      it 'should find the assignment associated with the campaign' do 
        @mock_campaign.assignments.should_receive(:find).with(77).and_return(@mock_assignment)
        outgoing_message = OutgoingMessage.message_from_attributes(@mock_campaign, @mock_user, @attributes)
      end
      
      it 'should set the assignment on the outgoing message' do 
        outgoing_message = OutgoingMessage.message_from_attributes(@mock_campaign, @mock_user, @attributes)
        outgoing_message.assignment.should == @mock_assignment
      end
      
      it 'should set the body of the outgoing message to the draft text' do 
        outgoing_message = OutgoingMessage.message_from_attributes(@mock_campaign, @mock_user, @attributes)
        outgoing_message.body.should == "hi"
      end
      
    end
    
  end
end