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
  
  it 'should be invalid without a description' do 
    @problem = Problem.new(:transport_mode_id => 5, :location => Route.new)
    @problem.valid? 
    @problem.errors.on(:description).should == 'Please enter a description'
  end
  
  it 'should be invalid without a subject' do 
    @problem = Problem.new(:transport_mode_id => 5, :location => Route.new)
    @problem.valid? 
    @problem.errors.on(:subject).should == 'Please enter a subject'
  end
  
  describe "when finding a location by attributes" do 
        
    before do 
      @problem = Problem.new(:transport_mode_id => 5)
      StopType.stub!(:codes_for_transport_mode).and_return([])
    end

    def expect_location(attributes, location_type, location)
      @problem.location_type = location_type
      @problem.location_attributes = attributes
      @problem.location_from_attributes
      @problem.locations.should == [location]
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
      Gazetteer.stub!(:find_stops_from_attributes).and_return({:results => [stop], :errors => []})
      attributes = { :name => 'name', :area => 'locality name' }
      expect_location(attributes, 'Stop',  stop)
    end
    
  end
  
end
