require 'spec_helper'

describe OperatorContact do
  before(:each) do
    @valid_attributes = {
      :operator_id => 1,
      :location_id => 1,
      :location_type => "value for location_type",
      :category => "value for category",
      :email => "test@example.com",
      :confirmed => false,
      :notes => "value for notes"
    }
  end

  after(:each) do
    OperatorContact.delete_all :operator_id => @valid_attributes[:operator_id]
  end

  it "should create a new instance given valid attributes" do
    OperatorContact.create!(@valid_attributes)
  end

  it "should be the only contact for the operator in this category" do
    existing_operator_contact = OperatorContact.create! @valid_attributes
    duplicate_operator_contact = OperatorContact.new @valid_attributes
    duplicate_operator_contact.should_not be_valid
  end

  it "should allow other contacts for this operator in different categories" do
    existing_operator_contact = OperatorContact.create! @valid_attributes
    similar_attributes = @valid_attributes.clone
    similar_attributes[:category] = "a different category"
    new_operator_contact = OperatorContact.new similar_attributes
    new_operator_contact.should be_valid
  end

end
