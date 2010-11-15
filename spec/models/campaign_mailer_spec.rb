require 'spec_helper'

describe CampaignMailer do
  
  describe 'when sending a campaign update' do 
  
    describe 'when not running in dry-run mode' do 
          
      before do
        CampaignMailer.stub!(:dry_run).and_return(false) 
        CampaignMailer.stub!(:sent_count).and_return(0)
        SentEmail.stub!(:find).and_return([])
        SentEmail.stub!(:create!)
        @mock_user = mock_model(User, :email => 'supporter@example.com', :name => 'Supporter')
        @mock_update_user = mock_model(User, :name => 'Update Sender')
        @mock_supporter = mock_model(CampaignSupporter, :supporter => @mock_user, 
                                                        :token => 'mytoken')
        @mock_supporter_association = mock('supporter association', :confirmed => [@mock_supporter])
        @mock_campaign = mock_model(Campaign, :campaign_supporters => @mock_supporter_association,
                                              :title => "A test campaign")
        @mock_update = mock_model(CampaignUpdate, :campaign => @mock_campaign, 
                                                  :user => @mock_update_user,
                                                  :update_attribute => true, 
                                                  :incoming_message => nil,
                                                  :text => 'an update')
      end
      
      it 'should create a sent email model for each update email sent' do 
        SentEmail.should_receive(:create!).with(:recipient => @mock_user, 
                                                :campaign => @mock_campaign, 
                                                :update => @mock_update)
        CampaignMailer.send_update(@mock_update)
      end
    
      it 'should not send an email to a recipient who has already received an email for this update' do 
        mock_sent_email = mock_model(SentEmail, :recipient => @mock_user)
        SentEmail.stub!(:find).and_return([mock_sent_email])
        CampaignMailer.should_not_receive(:deliver_update)
        CampaignMailer.send_update(@mock_update)
      end
      
      it 'should not send an email to the person who created the update' do 
        @mock_supporter.stub!(:supporter).and_return(@mock_update_user)
        CampaignMailer.should_not_receive(:deliver_update)
        CampaignMailer.send_update(@mock_update)
      end
      
    end
    
  end
  
end