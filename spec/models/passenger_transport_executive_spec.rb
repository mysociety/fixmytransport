require 'spec_helper'

describe PassengerTransportExecutive do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
    }
  end

  after(:each) do
    PassengerTransportExecutive.delete_all :name => @valid_attributes[:name]
  end

  it "should create a new instance given valid attributes" do
    PassengerTransportExecutive.create!(@valid_attributes)
  end

  it "should be the only one with that name" do
    PassengerTransportExecutive.create! @valid_attributes
    new_pte = PassengerTransportExecutive.new @valid_attributes
    new_pte.should_not be_valid
  end

  describe 'when asked if it is emailable' do 
    
    before do 
      @mock_route = mock_model(BusRoute)
      @pte = PassengerTransportExecutive.new
      @pte_contact = mock_model(PassengerTransportExecutiveContact)
    end
    
    it 'should return true if there is a general contact for category "Other" or a specific contact for that type of location and category "Other"' do 
      contact_conditions = ["category = 'Other' and (location_type = ? or location_type is null or location_type = '')", 'BusRoute']
      @pte.pte_contacts.stub!(:find).with(:all, :conditions => contact_conditions).and_return([@pte_contact])
      @pte.emailable?(@mock_route).should be_true
    end
    
    
    it 'should return false if there is no specific contact for that type of location or general contact with category "Other"' do
      contact_conditions = ["category = 'Other' and (location_type = ? or location_type is null or location_type = '')", 'BusRoute']
      @pte.pte_contacts.stub!(:find).with(:all, :conditions => contact_conditions).and_return([])
      @pte.emailable?(@mock_route).should be_false
    end
    
  end
  
  
  describe 'when asked for a contact for a category and location' do 
    
    before do 
      @pte = PassengerTransportExecutive.new
      @mock_route = mock_model(BusRoute)
      @bus_route_lateness_contact = mock_model(PassengerTransportExecutiveContact, :category => 'Lateness')
      @general_lateness_contact = mock_model(PassengerTransportExecutiveContact, :category => 'Lateness')
      @bus_route_other_contact = mock_model(PassengerTransportExecutiveContact, :category => 'Other')
      @general_other_contact = mock_model(PassengerTransportExecutiveContact, :category => 'Other')
      @pte.stub!(:contacts_for_location_type).and_return([@bus_route_other_contact, 
                                                          @bus_route_lateness_contact])
      @pte.stub!(:general_contacts).and_return([@general_other_contact, @general_lateness_contact])
    end
    
    it "should return a category specific contact for the type of location if there is one" do 
      @pte.contact_for_category_and_location('Lateness', @mock_route).should == @bus_route_lateness_contact
    end
    
    it 'should return a general contact for the type of location if there is no specific one' do 
      @pte.stub!(:contacts_for_location_type).and_return([@bus_route_other_contact])
      @pte.contact_for_category_and_location('Lateness', @mock_route).should == @bus_route_other_contact
    end
    
    it 'should return a category specific general contact if there are no location specific contacts' do 
      @pte.stub!(:contacts_for_location_type).and_return([])
      @pte.contact_for_category_and_location('Lateness', @mock_route).should == @general_lateness_contact
    end
    
    it 'should return a general contact failing all else' do
      @pte.stub!(:contacts_for_location_type).and_return([])
      @pte.stub!(:general_contacts).and_return([@general_other_contact])
      @pte.contact_for_category_and_location('Lateness', @mock_route).should == @general_other_contact
    end

    it 'should raise an error if no contact can be found' do 
      @pte.stub!(:contacts_for_location_type).and_return([])
      @pte.stub!(:general_contacts).and_return([])
      lambda{ @pte.contact_for_category_and_location('Lateness', @mock_route) }.should raise_error()
    end
    
    it 'should raise an error if no category or "Other" contacts exist' do 
      @operator.stub!(:contacts_for_location).with(@mock_stop).and_return([])
      @operator.stub!(:general_contacts).and_return([])
      lambda{ @operator.contact_for_category_and_location("Lateness", @mock_stop)}.should raise_error()
    
    end
  
  end
end
