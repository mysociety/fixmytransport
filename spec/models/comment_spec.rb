require 'spec_helper'

describe Comment do
  before(:each) do
    @valid_attributes = {
      :user_id => 1,
      :commented_id => 1,
      :commented_type => 'CampaignUpdate',
      :text => "value for text",
      :user_name => 'A name'
    }
  end

  it "should create a new instance given valid attributes" do
    Comment.create!(@valid_attributes)
  end
end
