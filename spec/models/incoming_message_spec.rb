require 'spec_helper'

describe IncomingMessage do
  
  before do 
    @mock_organization = mock("organization", :name => "a test organization", 
                                              :email => "organization@example.com")
    @mock_problem = mock_model(Problem, :emailable_organizations => [])
    @mock_campaign = mock_model(Campaign, :problem => @mock_problem, 
                                          :valid_local_parts => ['bob', 'ken'],
                                          :domain => 'example.com', 
                                          :title => 'a test campaign')
    @incoming_message = IncomingMessage.new
    @incoming_message.stub!(:campaign).and_return(@mock_campaign)
  end
  
  describe 'when getting body for html display' do 
    
    it 'should remove privacy sensitive things' do
      @incoming_message.stub!(:get_main_body_text_internal).and_return("test text") 
      @incoming_message.should_receive(:remove_privacy_sensitive_things).and_return("test text")
      @incoming_message.get_body_for_html_display
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


  end

end
