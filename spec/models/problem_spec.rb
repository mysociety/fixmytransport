# == Schema Information
# Schema version: 20100420165342
#
# Table name: problems
#
#  id                :integer         not null, primary key
#  subject           :text
#  description       :text
#  created_at        :datetime
#  updated_at        :datetime
#  reporter_id       :integer
#  stop_area_id      :integer
#  location_id       :integer
#  location_type     :string(255)
#  transport_mode_id :integer
#

require 'spec_helper'

describe Problem do
  
  before(:each) do
    @valid_attributes = {
      :subject => "value for subject",
      :description => "value for description",
      :location => mock_model(Stop),
      :transport_mode_id => 5
    }
  end

  it "should create a new instance given valid attributes" do
    problem = Problem.new(@valid_attributes)
    problem.valid?.should be_true
  end
  
  it 'should be invalid without a description' do 
    @valid_attributes[:description] = nil
    Problem.new(@valid_attributes).valid?.should be_false
  end
  
  it 'should be invalid without a subject' do 
    @valid_attributes[:subject] = nil
    Problem.new(@valid_attributes).valid?.should be_false
  end
  
  describe "when finding a location by attributes" do 
        
    before do 
      @problem = Problem.new(@valid_attributes)
      StopType.stub!(:codes_for_transport_mode).and_return([])
    end

    def expect_location(attributes, location)
      @problem.location_attributes = attributes
      @problem.location_from_attributes
      @problem.location.should == location
    end
    
    it 'should return nil if no location attributes have been set' do 
      @problem.location_attributes = nil
      @problem.location_from_attributes.should be_nil
    end
    
    it 'should ask for the stop type codes for the transport mode given' do 
      StopType.should_receive(:codes_for_transport_mode).with(5).and_return(['TES'])
      @problem.location_attributes = { :common_name => 'My stop', 
                                       :locality_name => 'My town' }
      @problem.location_from_attributes                           
    end
    
    it 'should return a stop if one is uniquely identified by the attributes' do 
      stop = mock_model(Stop)
      Stop.stub!(:find_from_attributes).and_return([stop])
      expect_location({:common_name => 'name', :locality_name => 'locality name'}, stop)
    end
    
    it 'should return a stop area if that stop area is the common root parent of all stops matching the attributes' do 
      first_stop = mock_model(Stop)
      second_stop = mock_model(Stop)
      stop_area = mock_model(StopArea)
      Stop.stub!(:find_from_attributes).and_return([first_stop, second_stop])
      Stop.stub!(:common_root_area).and_return(stop_area)
      expect_location({:common_name => 'name', :locality_name => 'locality name'}, stop_area)
    end
    
  end
  
end
