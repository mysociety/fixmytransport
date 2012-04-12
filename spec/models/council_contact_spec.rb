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

  after(:each) do
    CouncilContact.delete_all :area_id => 1
  end

  it "should create a new instance given valid attributes" do
    council_contact = CouncilContact.new @valid_attributes
    council_contact.should be_valid
  end

  it "should only allow one email address for a particular area and category" do
    existing_council_contact = CouncilContact.create! @valid_attributes
    new_council_contact = CouncilContact.new @valid_attributes
    new_council_contact.should_not be_valid
  end

  it "should allow another address for a different category" do
    existing_council_contact = CouncilContact.create! @valid_attributes
    similar_attributes = @valid_attributes.clone
    similar_attributes[:category] = "other"
    new_council_contact = CouncilContact.new similar_attributes
    new_council_contact.should be_valid
  end
  
  it 'should allow another address for the same area and category if the existing address is deleted' do 
    existing_council_contact = CouncilContact.create! @valid_attributes.merge(:deleted => true)
    new_council_contact = CouncilContact.new @valid_attributes
    new_council_contact.should be_valid
  end

  it 'should allow another address for the same area and category if the new address is deleted' do 
    existing_council_contact = CouncilContact.create! @valid_attributes
    new_council_contact = CouncilContact.new @valid_attributes.merge(:deleted => true)
    new_council_contact.should be_valid
  end
  
  it 'should allow another address for the same area and category if both addresses are deleted' do 
    existing_council_contact = CouncilContact.create! @valid_attributes.merge(:deleted => true)
    new_council_contact = CouncilContact.new @valid_attributes.merge(:deleted => true)
    new_council_contact.should be_valid
  end

end
