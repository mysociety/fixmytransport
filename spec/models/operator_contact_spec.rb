require 'spec_helper'

describe OperatorContact do
  before(:each) do
    @valid_attributes = {
      :operator_id => 1,
      :location_id => 1,
      :location_type => "value for location_type",
      :category => "value for category",
      :email => "value for email",
      :confirmed => false,
      :notes => "value for notes"
    }
  end

  it "should create a new instance given valid attributes" do
    OperatorContact.create!(@valid_attributes)
  end
end
