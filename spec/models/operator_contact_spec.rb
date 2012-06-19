require 'spec_helper'

describe OperatorContact do
  before(:each) do
    @valid_attributes = {
      :operator_id => 1,
      :location_persistent_id => 1,
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

  it 'should allow another address for the same operator and category if the existing address is deleted' do
    existing_operator_contact = OperatorContact.create! @valid_attributes.merge(:deleted => true)
    new_operator_contact = OperatorContact.new @valid_attributes
    new_operator_contact.should be_valid
  end

  it 'should allow another address for the same operator and category if the new address is deleted' do
    existing_operator_contact = OperatorContact.create! @valid_attributes
    new_operator_contact = OperatorContact.new @valid_attributes.merge(:deleted => true)
    new_operator_contact.should be_valid
  end

  it 'should allow another address for the same operator and category if both addresses are deleted' do
    existing_operator_contact = OperatorContact.create! @valid_attributes.merge(:deleted => true)
    new_operator_contact = OperatorContact.new @valid_attributes.merge(:deleted => true)
    new_operator_contact.should be_valid
  end

  it 'should allow other contacts for this operator in this category with different locations' do
    location_attributes = { :location_persistent_id => 55, :location_type => 'StopArea' }
    existing_operator_contact = OperatorContact.create! @valid_attributes.merge(location_attributes)
    duplicate_operator_contact = OperatorContact.new @valid_attributes
    duplicate_operator_contact.should be_valid
  end

  it 'should allow other contacts for this operator in this category that have been deleted' do
    existing_operator_contact = OperatorContact.create! @valid_attributes
    duplicate_operator_contact = OperatorContact.new @valid_attributes.merge(:deleted => 't')
    duplicate_operator_contact.should be_valid
  end

  it 'should allow other contacts for this operator in this category if the existing contacts have
      been deleted' do
    existing_operator_contact = OperatorContact.create! @valid_attributes.merge(:deleted => 't')
    duplicate_operator_contact = OperatorContact.new @valid_attributes
    duplicate_operator_contact.should be_valid
  end

  describe 'when asked if deleted or organization deleted' do

    before do
      @operator_contact = OperatorContact.new
    end

    it 'should return true if it is deleted' do
      @operator_contact.deleted = true
      @operator_contact.deleted_or_organization_deleted?.should be_true
    end

    it "should return true if it's operator's status is 'DEL'" do
      @operator_contact.deleted = false
      operator = Operator.new(:status => 'DEL')
      @operator_contact.operator = operator
      @operator_contact.deleted_or_organization_deleted?.should be_true
    end

  end

end
