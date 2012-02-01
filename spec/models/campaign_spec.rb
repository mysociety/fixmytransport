# == Schema Information
# Schema version: 20100506162135
#
# Table name: campaigns
#
#  id                :integer         not null, primary key
#  title             :text
#  description       :text
#  created_at        :datetime
#  updated_at        :datetime
#  reporter_id       :integer
#  location_id       :integer
#  location_type     :string(255)
#  transport_mode_id :integer
#

require 'spec_helper'

describe Campaign do

  describe 'in different statuses' do

    before do
      @campaign = Campaign.new
    end

    it 'should not be visible when hidden or new' do
      [:new, :hidden].each do |status|
        @campaign.status = status
        @campaign.visible?.should be_false
      end
    end

    it 'should be visible when confirmed or fixed' do
      [:confirmed, :fixed].each do |status|
        @campaign.status = status
        @campaign.visible?.should be_true
      end
    end

    it 'should be editable when new, confirmed, or fixed' do
      [:new, :confirmed, :fixed].each do |status|
        @campaign.status = status
        @campaign.editable?.should be_true
      end
    end

    it 'should not be editable when hidden' do
      [:hidden].each do |status|
        @campaign.status = status
        @campaign.editable?.should be_false
      end
    end

  end

  describe 'when generating a URL param' do 
  
    it 'should not create a param with a trailing dash' do 
      # title trimmed to max chars allowed in slug will end in space
      @campaign = Campaign.new(:title => 'aaaaa aaaaaa aaaaa aaaa aaa aaaaaaa aaa')
      @campaign.send(:build_a_slug).should == 'aaaaa-aaaaaa-aaaaa-aaaa-aaa-aaaaaaa'
    end
     
  end

  describe 'confirming' do

    def expect_no_confirmation(status)
      @campaign.status = status
      confirmed_at = Time.now - 5.days
      @campaign.confirmed_at = confirmed_at
      @campaign.confirm
      @campaign.status.should == status
      @campaign.confirmed_at.should == confirmed_at
    end

    def expect_confirmation(status)
      @campaign.status = status
      confirmed_at = Time.now - 5.days
      @campaign.confirmed_at = confirmed_at
      @campaign.confirm
      @campaign.status.should == :confirmed
      @campaign.confirmed_at.should > confirmed_at
    end

    before do
      @campaign = Campaign.new
    end

    describe 'if the status is new' do

      it 'should change the status and confirmation time' do
        expect_confirmation(:new)
      end

    end

    describe 'if the status is hidden' do

      it 'should not change the status or confirmation time' do
        expect_no_confirmation(:hidden)
      end

    end

    describe 'if the status is fixed' do

      it 'should not change the status or confirmation time' do
        expect_no_confirmation(:fixed)
      end

    end

  end

  describe 'when asked for its email address' do

    before do 
      MySociety::Config.stub!(:get).with("INCOMING_EMAIL_PREFIX", 'campaign-').and_return('prefix-')
      MySociety::Config.stub!(:get).with("INCOMING_EMAIL_DOMAIN", 'localhost').and_return('test.host')
    end
    
    it 'should return an email address generated from the prefix, key and domain' do
      @campaign = Campaign.new
      @campaign.stub!(:id).and_return(5049322)
      @campaign.key = @campaign.generate_key
      @campaign.email_address.should match(/prefix-lbhks-[a-z]{6}@test.host/)
    end

  end

  describe 'validating on update' do

    before do
      @campaign = Campaign.new
      @campaign.stub!(:new_record?).and_return(false)
      @campaign.update_attributes({})
      @campaign.valid?
    end

    it 'should be invalid without a description' do
      @campaign.errors.on(:description).should == 'Please give a brief description of your issue'
    end

    it 'should be invalid if the title is nil' do
      @campaign.errors.on(:title).should == 'Please enter a headline'
    end

    it 'should be invalid if the title is a single non-alphanumeric character' do 
      @campaign.title = '.'
      @campaign.valid? 
      @campaign.errors.on(:title).should == 'Please enter a headline with some words in it'
    end

    it 'should be valid regarding title if the title is a single lowercase character' do 
      @campaign.title = 'a'
      @campaign.valid? 
      @campaign.errors.on(:title).should == nil
    end
    
    it 'should be valid regarding title if the title is a single uppercase character' do 
      @campaign.title = 'A'
      @campaign.valid? 
      @campaign.errors.on(:title).should == nil
    end

  end

  describe 'when finding a campaign by campaign email' do

    before do 
      MySociety::Config.stub!(:get).with("INCOMING_EMAIL_PREFIX", 'campaign-').and_return('prefix-')
    end

    it 'should look for a campaign whose key is the key of the email' do
      Campaign.stub!(:email_domain).and_return("example.com")
      Campaign.should_receive(:find).with(:first, :conditions => ["lower(key) = ?", "cx-vgfdf"])
      Campaign.find_by_campaign_email("prefix-cx-vgfdf@example.com")
    end

    it 'should find a campaign for an email address whose case has been changed' do
      Campaign.stub!(:email_domain).and_return("example.com")
      Campaign.should_receive(:find).with(:first, :conditions => ["lower(key) = ?", 'cx-vgfdf'])
      Campaign.find_by_campaign_email("PREFIX-CX-VGFDF@example.com")
    end

  end
  
  describe 'when guessing which campaigns might match a given email' do 
    
    before do 
      MySociety::Config.stub!(:get).with("INCOMING_EMAIL_PREFIX", 'campaign-').and_return('prefix-')
      @mock_campaign = mock_model(Campaign)
    end
    
    it 'should look for a campaign whose id matches the decoded email id in the email' do 
      Campaign.should_receive(:find).with(:first, :conditions => ['id = ?', 75]).and_return(@mock_campaign)
      Campaign.guess_by_campaign_email('prefix-cx-vgfdf@example.com').should == @mock_campaign
    end
  end

  describe 'when removing a supporter' do 
    
    before do 
      @campaign = Campaign.new
      @user = User.new
      @campaign.stub!(:supporters).and_return([@user])
      @subscription = mock_model(Subscription, :user => @user)
      @campaign.stub!(:subscriptions).and_return([@subscription])
    end
    
    it 'should delete the supporter relationship' do 
      @campaign.supporters.should_receive(:delete).with(@user)
      @campaign.remove_supporter(@user)
    end
    
    it 'should remove any subscription the user has to that campaign' do 
      @campaign.subscribers.should_receive(:delete).with(@user)
      @campaign.remove_supporter(@user)
    end
  
  end
  
  describe 'when adding user as a supporter' do

    before do
      @user = mock_model(User)
      @campaign = Campaign.new
      @mock_supporters = mock('campaign supporter association')
      @mock_subscriptions = mock('subscriptions association')
      @campaign.stub!(:campaign_supporters).and_return(@mock_supporters)
      @campaign.stub!(:initiator).and_return(mock_model(User))
      @campaign.stub!(:subscriptions).and_return(@mock_subscriptions)
      @mock_campaign_supporter = mock_model(CampaignSupporter)
      @mock_subscriber = mock_model(User)
      @existing_campaign_supporter = mock_model(CampaignSupporter, :supporter_id => @user.id)
      @mock_supporters.stub!(:create!).and_return(@mock_campaign_supporter)
      @mock_subscriptions.stub!(:create!).and_return(@mock_subscriber)
    end

    describe 'if the user is not already a supporter' do

      before do
        @campaign.stub!(:supporters).and_return([])
      end

      it 'should add the user as a supporter' do
        @mock_supporters.should_receive(:create!).with(:supporter => @user)
        @campaign.add_supporter(@user)
      end

      it 'should create an unconfirmed subscription for the user' do 
        @mock_subscriptions.should_receive(:create!).with(:user => @user)
        @campaign.add_supporter(@user)
      end

      it 'should return the new campaign supporter model' do
        @campaign.add_supporter(@user).should == @mock_campaign_supporter
      end

    end

    describe 'if the user is already a supporter' do

      before do
        @campaign.stub!(:supporters).and_return([@user])
        @campaign.stub!(:campaign_supporters).and_return([@existing_campaign_supporter])
      end

      it 'should return nil' do
        @campaign.add_supporter(@user).should == nil
      end

    end

    describe 'if the user is the campaign initiator' do

      before do
        @campaign.stub!(:supporters).and_return([])
        @campaign.stub!(:initiator).and_return(@user)
      end

      it 'should not add the user as a supporter' do
        @mock_supporters.should_not_receive(:create!)
        @campaign.add_supporter(@user)
      end

      it 'should return nil' do
        @campaign.add_supporter(@user).should == nil
      end

    end

  end

end
