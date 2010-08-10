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
  
  it 'should be invalid without a description' do 
    @campaign = Campaign.new(:transport_mode_id => 5, :location => Route.new)
    @campaign.valid? 
    @campaign.errors.on(:description).should == 'Please give a brief description of your campaign'
  end
  
  it 'should be invalid without a title' do 
    @campaign = Campaign.new(:transport_mode_id => 5, :location => Route.new)
    @campaign.valid? 
    @campaign.errors.on(:title).should == 'Please give your campaign a title'
  end
  

end
