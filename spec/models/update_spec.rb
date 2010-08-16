require 'spec_helper'

describe Update do
  before(:each) do
    @valid_attributes = {
      :problem_id => 1,
      :reporter_id => 1,
      :text => "value for text",
      :status_code => false,
      :confirmed_at => Time.now
    }
  end

  it "should create a new instance given valid attributes" do
    Update.create!(@valid_attributes)
  end
end
