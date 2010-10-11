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
  
  describe ' validating on update' do 
    
    before do 
      @campaign = Campaign.new
      @campaign.stub!(:new_record?).and_return(false)
      @campaign.update_attributes({})
      @campaign.valid?
    end
    
    it 'should be invalid without a description' do 
      @campaign.errors.on(:description).should == 'Please give a brief description of your campaign'
    end
  
    it 'should be invalid without a title' do 
      @campaign.errors.on(:title).should == 'Please give your campaign a title'
    end
    
    it 'should be invalid without a subdomain' do 
      @campaign.errors.on(:subdomain).should == 'Please give your campaign a short name'
    end
    
    it 'should be invalid if the subdomain is longer than 16 characters' do 
      @campaign.subdomain = 'testtesttesttestt'
      @campaign.valid?
      @campaign.errors.on(:subdomain).should == 'The short name must be 16 characters or less'
    end
    
    it 'should be invalid if the subdomain is shorter than 6 characters' do 
      @campaign.subdomain = 'test'
      @campaign.valid?
      @campaign.errors.on(:subdomain).should == 'The short name must be at least 6 characters long'
    end
    
    it 'should be invalid if the subdomain does not have at least one letter' do 
      @campaign.subdomain = '99999999'
      @campaign.valid?
      @campaign.errors.on(:subdomain).should == 'The short name must contain at least one letter'
    end
    
    it 'should be invalid if the subdomain contains non alphanumeric characters' do
      @campaign.subdomain = '%testtest'
      @campaign.valid?
      @campaign.errors.on(:subdomain).should == 'The short name can only contain lowercase letters and numbers'
    end
    
    it 'should be invalid if it contains uppercase letters' do 
      @campaign.subdomain = 'TESTtest'
      @campaign.valid? 
      @campaign.errors.on(:subdomain).should == 'The short name can only contain lowercase letters and numbers'
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
