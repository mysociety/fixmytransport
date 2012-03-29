require 'spec_helper'

describe PassengerTransportExecutiveContact do

  before(:each) do
    @pte = PassengerTransportExecutive.create! :name => "Imaginary PTE"
    @valid_attributes = {
      :passenger_transport_executive => @pte,
      :category => "Example category",
      :email => "test@example.com",
      :notes => "Some notes here"
    }
  end

  after(:each) do
    PassengerTransportExecutiveContact.delete_all :passenger_transport_executive_id => @pte
    @pte.destroy
  end

  it "should create a new instance given valid attributes" do
    new_ptec = PassengerTransportExecutiveContact.new @valid_attributes
    new_ptec.should be_valid
  end

  it "should be the only contact for the PTE in this category" do
    existing_ptec = PassengerTransportExecutiveContact.create! @valid_attributes
    duplicate_ptec = PassengerTransportExecutiveContact.new @valid_attributes
    duplicate_ptec.should_not be_valid
  end

  it "should allow other contacts for this PTE in different categories" do
    existing_ptec = PassengerTransportExecutiveContact.create! @valid_attributes
    similar_attributes = @valid_attributes.clone
    similar_attributes[:category] = "A different category"
    new_ptec = PassengerTransportExecutiveContact.new similar_attributes
    new_ptec.should be_valid
  end

end
