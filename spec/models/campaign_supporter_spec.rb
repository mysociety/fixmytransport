require 'spec_helper'

describe CampaignSupporter do
  
  describe 'when confirming support' do 
    
    before do 
      @campaign_supporter = CampaignSupporter.new
      @user = mock_model(User)
      @campaign = mock_model(Campaign)
      @campaign_supporter.stub!(:supporter).and_return(@user)
      @campaign_supporter.stub!(:campaign).and_return(@campaign)
    end
    
    it 'should set the confirmed at timestamp' do 
      @campaign_supporter.should_receive(:confirmed_at)
      @campaign_supporter.should_receive(:save!)
      @campaign_supporter.confirm!
    end
    
    it "should confirm the user's subscription to the campaign" do 
      Subscription.should_receive(:find).with(:first, :conditions => ['target_id = ? AND target_type = ? AND user_id = ?',
                                                                      @campaign.id, 'Campaign', @user.id])
      @campaign_supporter.confirm!
    end
     
  end

end