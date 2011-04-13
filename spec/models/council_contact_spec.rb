require 'spec_helper'

describe CouncilContact do
  before(:each) do
    @valid_attributes = {
      :area_id => 1,
      :category => "value for category",
      :email => "test@example.com",
      :confirmed => false,
      :notes => "value for notes"
    }
  end

  it "should create a new instance given valid attributes" do
    CouncilContact.create!(@valid_attributes)
  end
end
