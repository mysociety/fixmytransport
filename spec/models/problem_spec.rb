# == Schema Information
# Schema version: 20100506162135
#
# Table name: stories
#
#  id                :integer         not null, primary key
#  title             :text
#  story             :text
#  created_at        :datetime
#  updated_at        :datetime
#  reporter_id       :integer
#  stop_area_id      :integer
#  location_id       :integer
#  location_type     :string(255)
#  transport_mode_id :integer
#

require 'spec_helper'

describe Story do
  
  it 'should be invalid without a description' do 
    @story = Story.new(:transport_mode_id => 5, :location => Route.new)
    @story.valid? 
    @story.errors.on(:story).should == 'Please tell us your story'
  end
  
  it 'should be invalid without a title' do 
    @story = Story.new(:transport_mode_id => 5, :location => Route.new)
    @story.valid? 
    @story.errors.on(:title).should == 'Please tell us the title of your story'
  end
  
  describe "when finding a location by attributes" do 
        
    before do 
      @story = Story.new(:transport_mode_id => 5)
      StopType.stub!(:codes_for_transport_mode).and_return([])
    end

    def expect_location(attributes, location_type, location)
      @story.location_type = location_type
      @story.location_attributes = attributes
      @story.location_from_attributes
      @story.locations.should == [location]
    end
    
    it 'should return nil if no location attributes have been set' do 
      @story.location_attributes = nil
      @story.location_from_attributes.should be_nil
    end
    
    it 'should ask for the stop type codes for the transport mode given' do 
      StopType.should_receive(:codes_for_transport_mode).with(5).and_return(['TES'])
      @story.location_type = 'Stop'
      @story.location_attributes = { :name => 'My stop', 
                                       :area => 'My town' }
      @story.location_from_attributes                           
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
