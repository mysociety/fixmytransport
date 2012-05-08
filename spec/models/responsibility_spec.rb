
require 'spec_helper'

describe Responsibility do

  describe 'when validating' do

    it 'should be invalid if it is an operator responsibility without an organization peristent id' do
      expected_error = 'Please choose a company to report the problem to'
      responsibility = Responsibility.new(:organization_type => 'Operator')
      responsibility.valid?.should == false
      responsibility.errors.on(:organization_persistent_id).should == expected_error
    end

    it 'should be invalid if it is a council responsibility without an organization id' do
      expected_error = "can't be blank"
      responsibility = Responsibility.new(:organization_type => 'Council')
      responsibility.valid?.should == false
      responsibility.errors.on(:organization_id).should == "can't be blank"
    end

    it 'should be invalid if it is a PTE responsibility without an organization id' do
      expected_error = "can't be blank"
      responsibility = Responsibility.new(:organization_type => 'PassengerTransportExecutive')
      responsibility.valid?.should == false
      responsibility.errors.on(:organization_id).should == "can't be blank"
    end

  end

end