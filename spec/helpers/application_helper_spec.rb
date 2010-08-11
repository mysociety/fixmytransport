require 'spec_helper'

describe ApplicationHelper do

  describe 'when creating search links' do 
  
    it 'should create links with URI-encoded search params' do 
      helper.external_search_link("some=& string").should == "http://www.google.co.uk/search?ie=UTF-8&q=some%3D%26+string"
    end
    
  end
  
  describe 'when using "on the" or "at the" to describe a location' do 
    
    it 'should use "on the" for a route' do 
      helper.on_or_at_the(Route.new).should == 'on the'
    end
    
    it 'should use "at the" for a stop' do 
      helper.on_or_at_the(Stop.new).should == 'at the'
    end
    
    it 'should use "at the" for a stop area' do 
      helper.on_or_at_the(StopArea.new).should == 'at the'
    end
  
  end
  
  describe 'when returning the readable location type of a location' do 
  
    it 'should return "stop" for a stop' do 
      helper.readable_location_type(Stop.new(:stop_type => 'BCS')).should == 'stop'
    end
    it 'should return "route" for a route' do 
      helper.readable_location_type(Route.new).should == 'route'
    end
    
    it 'should return "stop area" for a stop area' do 
      helper.readable_location_type(StopArea.new(:area_type => 'GBCS')).should == 'stop area'
    end
    
    it 'should return "station" for a train stop' do 
      helper.readable_location_type(Stop.new(:stop_type => 'RLY')).should == 'station'
    end
    
    it 'should return "station" for a train stop area' do 
      helper.readable_location_type(StopArea.new(:area_type => 'GRLS')).should == 'station'
    end
  
    it 'should return "station" for a metro/tram stop' do 
      helper.readable_location_type(Stop.new(:stop_type => 'TMU')).should == 'station'
    end
  
    it 'should return "station" for a metro/tram stop area' do 
      helper.readable_location_type(StopArea.new(:area_type => 'GTMU')).should == 'station'
    end  
    
  end

end
