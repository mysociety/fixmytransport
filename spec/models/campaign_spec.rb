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

    it 'should be visible when confirmed or successful' do 
      [:confirmed, :successful].each do |status|
        @campaign.status = status
        @campaign.visible?.should be_true
      end
    end
  
    it 'should be editable when new, confirmed, or successful' do 
      [:new, :confirmed, :successful].each do |status|
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
        expect_no_confirmation(:successful)
      end
      
    end
    
    describe 'if the status is successful' do 
      
      it 'should not change the status or confirmation time' do
        expect_no_confirmation(:successful)
      end
      
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
  
    it 'should be invalid without a title' do 
      @campaign.errors.on(:title).should == 'Please give your campaign a headline'
    end
    
  end
  
  describe 'when finding a campaign by campaign email' do 
    
    it 'should look for a campaign whose subdomain is the subdomain of the email' do 
      Campaign.stub!(:email_domain).and_return("example.com")
      Campaign.should_receive(:find).with(:first, :conditions => ["subdomain = ?", "campaign"])
      Campaign.find_by_campaign_email("test@campaign.example.com")
    end
  
  end
  
end
