require 'spec_helper'

describe CampaignComment do
  before(:each) do
    @valid_attributes = {
      :user_id => 1,
      :campaign_update_id => 1,
      :text => "value for text"
    }
  end

  it "should create a new instance given valid attributes" do
    CampaignComment.create!(@valid_attributes)
  end
end
