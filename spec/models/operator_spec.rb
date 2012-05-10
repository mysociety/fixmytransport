# == Schema Information
# Schema version: 20100707152350
#
# Table name: operators
#
#  id              :integer         not null, primary key
#  code            :string(255)
#  name            :text
#  created_at      :datetime
#  updated_at      :datetime
#  short_name      :string(255)
#  email           :text
#  email_confirmed :boolean
#  notes           :text
#

require 'spec_helper'

describe Operator do


  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :name => "value for name",
      :noc_code => 'NOXX'
    }
    @model_type = Operator
    @default_attrs = { :name => 'value for name' }
    @expected_identity_hash = { :noc_code => 'NOXX' }
    @expected_temporary_identity_hash = { :id => nil }
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"

  it_should_behave_like "a model that exists in data generations and has slugs"

  it "should create a new instance given valid attributes" do
    operator = Operator.new(@valid_attributes)
    operator.valid?.should be_true
  end

  it 'should require the name attribute' do
    operator = Operator.new(@valid_attributes)
    operator.name = nil
    operator.valid?.should be_false
  end

  describe 'when validating' do

    fixtures default_fixtures

    before do
      @operator = Operator.new(@valid_attributes)
    end

    it 'should be invalid if it has a noc code already used in this generation' do
      @operator.noc_code = operators(:a_train_company).noc_code
      @operator.valid?.should == false
    end

    it 'should be valid if it has a noc code already used in a previous generation' do
      noc_code = 'TRAI'
      previous_operator = nil
      Operator.in_generation(PREVIOUS_GENERATION) do
        previous_operator = Operator.find(:first, :conditions => ['noc_code = ?', noc_code])
      end
      previous_operator.should_not == nil
      @operator.noc_code = previous_operator.noc_code
      @operator.valid?.should == true
    end

  end


  describe 'when asked for categories for a location' do

    before do
      @mock_stop = mock_model(Stop)
      @general_contact = mock('general contacts', :category => 'general other')
      @specific_contact = mock('specific contacts', :category => 'specific other')
      @operator = Operator.new
      @operator.stub!(:contacts_for_location).with(@mock_stop).and_return([@specific_contact])
      @operator.stub!(:general_contacts).and_return([@general_contact])
    end

    it 'should return the categories for the location if there are any' do
      @operator.categories(@mock_stop).should == ['specific other']
    end

    it 'should return general categories if there are no categories specific to the location' do
      @operator.stub!(:contacts_for_location).and_return([])
      @operator.categories(@mock_stop).should == ['general other']
    end

  end

  describe 'when asked for a contact for a category and location' do

    before do
      @mock_stop = mock_model(Stop)
      @operator = Operator.new
      @general_other_contact = mock_model(OperatorContact, :category => 'Other')
      @location_other_contact = mock(OperatorContact, :category => 'Other',
                                                      :location_id => @mock_stop.id,
                                                      :location_type => @mock_stop.class.to_s)
      @general_category_contact = mock_model(OperatorContact, :category => 'Lateness')
      @location_category_contact = mock(OperatorContact, :category => 'Lateness',
                                                         :location_id => @mock_stop.id,
                                                         :location_type => @mock_stop.class.to_s)

      @operator.stub!(:contacts_for_location).with(@mock_stop).and_return([@location_other_contact,
                                                                           @location_category_contact])
      @operator.stub!(:general_contacts).and_return([@general_other_contact,
                                                     @general_category_contact])
    end

    it 'should return the location-specific contact for that category if there is one' do
      @operator.contact_for_category_and_location("Lateness", @mock_stop).should == @location_category_contact
    end

    it 'should return the location-specific "Other" contact if there is not one specifically for the category' do
      @operator.stub!(:contacts_for_location).with(@mock_stop).and_return([@location_other_contact])
      @operator.contact_for_category_and_location("Lateness", @mock_stop).should == @location_other_contact
    end

    it 'should return the general contact for that category if there is no location-specific category or "Other" contact' do
      @operator.stub!(:contacts_for_location).with(@mock_stop).and_return([])
      @operator.contact_for_category_and_location("Lateness", @mock_stop).should == @general_category_contact
    end

    it 'should return the general "Other" contact if there is no category or location-specific contact' do
      @operator.stub!(:contacts_for_location).with(@mock_stop).and_return([])
      @operator.stub!(:general_contacts).and_return([@general_other_contact])
      @operator.contact_for_category_and_location("Lateness", @mock_stop).should == @general_other_contact
    end

    it 'should raise an error if no category or "Other" contacts exist' do
      @operator.stub!(:contacts_for_location).with(@mock_stop).and_return([])
      @operator.stub!(:general_contacts).and_return([])
      lambda{ @operator.contact_for_category_and_location("Lateness", @mock_stop)}.should raise_error()

    end

  end

  describe 'when creating operators' do

    it "should consider an associated route operator invalid if the attributes passed don't contain an '_add' item" do
      operator = Operator.new(@valid_attributes)
      operator.route_operator_invalid({ "_add" => "0",
                                        "route_id" => 44 } ).should be_true
    end

    it "should consider an associated route operator valid if the attributes passed contain an '_add' item whose value is 1" do
      @valid_attributes["route_operators_attributes"] =
      @operator = Operator.create(@valid_attributes)
      @operator.route_operator_invalid({ "_add" => "1",
                                        "route_id" => 44 }).should be_false
      @operator.destroy
    end

  end

  it 'should respond to emailable? correctly' do
    mock_station = mock_model(StopArea, :type => 'GRLS', :persistent_id => 55)
    mock_operator_contact = mock_model(OperatorContact)
    operator = Operator.new
    operator.operator_contacts.stub!(:find).and_return([mock_operator_contact])
    operator.emailable?(mock_station).should be_true

    operator.operator_contacts.stub!(:find).and_return([])
    operator.operator_contacts.delete
    operator.emailable?(mock_station).should be_false
  end

end
