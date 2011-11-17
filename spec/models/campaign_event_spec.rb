require 'spec_helper'

describe CampaignEvent do
  before(:each) do
    @valid_attributes = {
      :event_type => "comment_added",
      :campaign_id => 1,
      :described_type => "Comment",
      :described_id => 1    
      }
  end

  it "should create a new instance given valid attributes" do
    campaign = CampaignEvent.new(@valid_attributes)
    campaign.valid?.should be_true
  end
  
  describe "when returning it's title" do 
    
    before do
      @campaign = mock_model(Campaign, :initiator => mock_model(User, :name => 'Campaign Initiator',
                                                                      :first_name => 'Campaign'),
                                       :location => mock_model(Stop, :readable_type => 'stop'))
      @campaign_event = CampaignEvent.new(:campaign => @campaign)
    end
    
    it 'should return appropriate text for an incoming message received' do 
      @incoming_message = mock_model(IncomingMessage, :safe_from => 'Test Person') 
      @campaign_event.stub!(:event_type).and_return('incoming_message_received')
      @campaign_event.stub!(:described).and_return(@incoming_message)
      @campaign_event.title.should == 'Test Person responded to Campaign Initiator'
    end
    
    it 'should return appropriate text for an outgoing message sent' do 
      @message_author =  mock_model(User, :name => 'Message Author')
      @outgoing_message = mock_model(OutgoingMessage, :author => @message_author,
                                                      :recipient_name => 'Message Recipient',
                                                      :assignment_text => ' as advised by An Expert')
      @campaign_event.stub!(:event_type).and_return('outgoing_message_sent')
      @campaign_event.stub!(:described).and_return(@outgoing_message)
      @campaign_event.title.should == 'Message Author wrote to Message Recipient as advised by An Expert'
    end
    
    it 'should return appropriate text for a completed assignment' do 
      @assignment = mock_model(Assignment, :task_type => 'write_to_transport_organization',
                                           :user => @campaign.initiator,
                                           :data => {:organizations => [{:name => 'Transport Org'}]})
      @campaign_event.stub!(:event_type).and_return('assignment_completed')
      @campaign_event.stub!(:described).and_return(@assignment)
      @campaign_event.title.should == 'Campaign Initiator wrote to Transport Org'
    end
    
    it 'should return appropriate text for an assignment given' do 
      @assignment_creator = mock_model(User, :name => 'An Expert')
      @assignment = mock_model(Assignment, :task_type => 'write_to_other',
                                           :creator => @assignment_creator,
                                           :data => {:name => 'An Other'},
                                           :user => @campaign.initiator)
      @campaign_event.stub!(:event_type).and_return('assignment_given')
      @campaign_event.stub!(:described).and_return(@assignment)
      @campaign_event.title.should == 'An Expert advised Campaign to write to An Other.'
    end
    
    it 'should return appropriate text for an assignment in progress' do 
      @assignment = mock_model(Assignment, :task_type => 'find_transport_organization_details',
                                           :creator => @assignment_creator,
                                           :user => @campaign.initiator,
                                           :campaign => @campaign)
      @campaign_event.stub!(:event_type).and_return('assignment_in_progress')
      @campaign_event.stub!(:described).and_return(@assignment)
      @campaign_event.title.should == 'Campaign Initiator found the company that runs this stop'
    end
    
    it 'should return appropriate text for a campaign update' do 
      @campaign_update = mock_model(CampaignUpdate, :update_text => 'campaigns.show.added_an_update',
                                                    :user => @campaign.initiator)
      @campaign_event.stub!(:event_type).and_return('campaign_update_added')
      @campaign_event.stub!(:described).and_return(@campaign_update)
      @campaign_event.title.should == 'Campaign Initiator added an update'
    end
    
    it 'should return appropriate text for a comment' do 
      @comment = mock_model(Comment, :header => 'A User commented')
      @campaign_event.stub!(:event_type).and_return('comment_added')
      @campaign_event.stub!(:described).and_return(@comment)
      @campaign_event.title.should == 'A User commented'
    end
    
    it 'should return appropriate text for a resent problem report' do
      @operator = mock_model(Operator, :name => 'An Operator')  
      SentEmail.stub!(:find).with(1).and_return(mock_model(SentEmail, :recipient => @operator))
      @campaign_event.stub!(:event_type).and_return('problem_report_resent')
      @campaign_event.stub!(:data).and_return({:sent_emails => [1]})
      @campaign_event.title.should == 'The problem report was resent to An Operator'
    end
    
  end
  
end
