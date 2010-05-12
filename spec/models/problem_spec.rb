# == Schema Information
# Schema version: 20100506162135
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
  
  it 'should be invalid without a description'
  
  it 'should be invalid without a subject'
  
  describe "when finding a location by attributes" do 
        
    before do 
      @problem = Problem.new(:transport_mode_id => 5)
      StopType.stub!(:codes_for_transport_mode).and_return([])
    end

    def expect_location(attributes, location_type, location)
      @problem.location_type = location_type
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
      @problem.location_type = 'Stop'
      @problem.location_attributes = { :name => 'My stop', 
                                       :area => 'My town' }
      @problem.location_from_attributes                           
    end
    
    it 'should return a route if one is uniquely identified by the number and transport mode' do 
      route = mock_model(Route, :becomes => route)
      Route.stub!(:find_from_attributes).and_return([route])
      attributes = { :route_number => 'number' }
      expect_location(attributes, 'Route', route)
    end
    
    it 'should return a stop if one is uniquely identified by the attributes' do 
      stop = mock_model(Stop)
      Stop.stub!(:find_from_attributes).and_return([stop])
      attributes = { :name => 'name', :area => 'locality name' }
      expect_location(attributes, 'Stop',  stop)
    end
    
    it 'should return a stop area if that stop area is the common root parent of all stops matching the attributes' do 
      first_stop = mock_model(Stop)
      second_stop = mock_model(Stop)
      stop_area = mock_model(StopArea)
      Stop.stub!(:find_from_attributes).and_return([first_stop, second_stop])
      Stop.stub!(:common_area).and_return(stop_area)
      attributes = { :name => 'name', :area => 'locality name' }
      expect_location(attributes, 'Stop', stop_area)
    end
    
  end
  
end
