require 'spec_helper'

describe IncomingMessage do

  before do
    @mock_organization = mock("organization", :name => "a test organization",
                                              :emails => ["organization@example.com"])
    @mock_problem = mock_model(Problem, :emailable_organizations => [])
    @mock_campaign = mock_model(Campaign, :problem => @mock_problem,
                                          :valid_local_parts => ['bob', 'ken'],
                                          :domain => 'example.com',
                                          :title => 'a test campaign')
    @incoming_message = IncomingMessage.new
    @incoming_message.stub!(:campaign).and_return(@mock_campaign)
  end

  describe 'when getting main body text' do

    before do
      @mock_campaign = mock_model(Campaign)
      @mock_raw_email = mock_model(RawEmail)
      @mock_mail = mock('mail object', :total_part_count= => true,
                                       :body => 'test text',
                                       :content_type => 'text/plain')
      @incoming_message = IncomingMessage.new
      @incoming_message.stub!(:campaign).and_return(@mock_campaign)
      @incoming_message.stub!(:raw_email).and_return(@mock_raw_email)
      @incoming_message.stub!(:remove_privacy_sensitive_things).and_return{ |text| text }
      @incoming_message.stub!(:mail).and_return(@mock_mail)
      @incoming_message.stub!(:save!).and_return(true)
      FixMyTransport::Email.stub!(:get_main_body_text_part).and_return(@mock_mail)
    end

    it 'should return a note if there is no main body' do
      FixMyTransport::Email.stub!(:get_main_body_text_part).and_return(nil)
      @incoming_message.main_body_text.should == '[ Email has no body, please see attachments ]'
    end

    it 'should remove privacy sensitive things' do
      @incoming_message.should_receive(:remove_privacy_sensitive_things).and_return("test text")
      @incoming_message.main_body_text
    end

    it 'should return plain text if the main body part is html' do
      mock_part = mock('email part', :content_type => 'text/html',
                                     :body => 'this is <b>really</b> important')
      FixMyTransport::Email.stub!(:get_main_body_text_part).and_return(mock_part)
      FixMyTransport::Email.should_receive(:_get_attachment_text_internal_one_file).and_return("this is really important")
      @incoming_message.main_body_text
    end

  end

  describe 'when masking special emails' do

    it 'should mask the responsible organization email address' do
      @mock_problem.stub!(:emailable_organizations).and_return([@mock_organization])
      text = "this is from organization@example.com indeed"
      expected_text = "this is from [a test organization problem reporting email] indeed"
      @incoming_message.mask_special_emails(text).should_not match('organization@example.com')
    end

    it 'should mask the campaign email addresses' do
      text = "it is to bob@example.com and ken@example.com"
      expected_text = 'it is to [a test campaign email] and [a test campaign email]'
      @incoming_message.mask_special_emails(text).should == expected_text
    end

    it 'should mask an upppercase or mixed case version of the campaign email address' do 
      text = "it is to BOB@EXAMPLE.COM and Ken@Example.com"
      expected_text = 'it is to [a test campaign email] and [a test campaign email]'
      @incoming_message.mask_special_emails(text).should == expected_text
      
    end

  end

  describe 'when asked for a safe from address' do

    it 'should return a name untouched' do
      @incoming_message.stub!(:from).and_return("Bob Jones")
      @incoming_message.safe_from.should == 'Bob Jones'
    end

    it 'should substitute the organization name for a known organization email' do
      @mock_problem.stub!(:emailable_organizations).and_return([@mock_organization])
      @incoming_message.stub!(:from).and_return("organization@example.com")
      @incoming_message.safe_from.should == 'a test organization'
    end

    it 'should mask an unknown email' do
      @incoming_message.stub!(:from).and_return("unknown@example.com")
      @incoming_message.safe_from.should == '[email address]'
    end
  end

  describe 'when creating a message from a tmail instance' do

    before do
      @mock_tmail = mock("TMail instance", :subject => 'a subject',
                                           :friendly_from => "test@example.com",
                                           :from => 'test@example.com')
      @raw_email_data = {}
      @campaign = mock_model(Campaign, :campaign_events => mock('campaign events', :create! => true))
      @raw_email = mock_model(RawEmail)
      RawEmail.stub!(:create!).and_return(@raw_email)
      @incoming_message = mock_model(IncomingMessage)
      IncomingMessage.stub!(:create!).and_return(@incoming_message)
    end

    it 'should create a raw email' do
      RawEmail.should_receive(:create!).with(:data => @raw_email_data)
      IncomingMessage.create_from_tmail(@mock_tmail, @raw_email_data, @campaign)
    end

    it 'should set the from address to an empty string if there is no from address' do
      @email = TMail::Mail.new
      IncomingMessage.create_from_tmail(@email, @raw_email_data, @campaign)
    end

    it 'should create an incoming message' do
      IncomingMessage.should_receive(:create!).with(:subject => 'a subject',
                                                    :campaign => @campaign,
                                                    :raw_email => @raw_email,
                                                    :from => 'test@example.com')
      IncomingMessage.create_from_tmail(@mock_tmail, @raw_email_data, @campaign)
    end

    it 'should create an "incoming_message_received" campaign event' do
      @campaign.campaign_events.should_receive(:create!).with(:event_type => 'incoming_message_received',
                                                              :described => @incoming_message)
      IncomingMessage.create_from_tmail(@mock_tmail, @raw_email_data, @campaign)
    end

    it 'should return the incoming message' do
      IncomingMessage.create_from_tmail(@mock_tmail, @raw_email_data, @campaign).should == @incoming_message
    end

  end

end
