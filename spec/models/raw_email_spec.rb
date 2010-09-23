require 'spec_helper'

describe RawEmail do
  before(:each) do
    @valid_attributes = {
      :data_binary => "data binary"
    }
  end

  it "should create a new instance given valid attributes" do
    RawEmail.create!(@valid_attributes)
  end
end
