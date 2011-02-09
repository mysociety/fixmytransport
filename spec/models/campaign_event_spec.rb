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
    CampaignEvent.create!(@valid_attributes)
  end
end
