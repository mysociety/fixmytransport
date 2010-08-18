require 'spec_helper'

describe PassengerTransportExecutive do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
    }
  end

  it "should create a new instance given valid attributes" do
    PassengerTransportExecutive.create!(@valid_attributes)
  end
  
  it 'should respond to emailable? correctly' do 
    pte = PassengerTransportExecutive.new
    pte.email = "test email"
    pte.emailable?.should be_true
    pte.email = ''
    pte.emailable?.should be_false
    pte.email = nil
    pte.emailable?.should be_false
  end
end
