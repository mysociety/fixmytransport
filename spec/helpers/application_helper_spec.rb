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
  
  describe 'when giving an "at_the_location" string' do 
    
    it 'should describe a bus stop as "at the Williams Avenue bus/tram stop"' do
      stop = mock_model(Stop, :name => "Williams Avenue", :transport_mode_names => ['Bus'])
      helper.at_the_location(stop).should == "at the Williams Avenue bus/tram stop"
    end 
    
    it 'should describe a bus route as "on the C10"' do 
      route = mock_model(BusRoute, :name => 'C10 bus route')
      helper.at_the_location(route).should == 'on the C10 bus route'
    end
    
    it 'should describe a train station as "at London Euston Rail Station"' do 
      station = mock_model(StopArea, :area_type => 'GRLS', 
                                     :name => 'London Euston Rail Station',
                                     :transport_mode_names => ['Train'])
      helper.at_the_location(station).should == 'at London Euston Rail Station'
    end
  
    it 'should describe a metro station as "at Baker Street Underground Station"' do 
      station = mock_model(StopArea, :area_type => 'GTMU', 
                                     :name => 'Baker Street Underground Station', 
                                     :transport_mode_names => ['Tram/Metro'])
      helper.at_the_location(station).should == 'at Baker Street Underground Station'
    end
    
    it 'should describe a ferry station as "at Armadale Ferry Terminal"' do 
      station = mock_model(StopArea, :area_type => 'GFTD', 
                                     :name => 'Armadale Ferry Terminal',
                                     :transport_mode_names => ['Ferry'])
      helper.at_the_location(station).should == 'at the Armadale Ferry Terminal'
    end
    
    it 'should describe a bus station as "at the Sevenoaks Bus Station"' do 
      station = mock_model(StopArea, :area_type => 'GBCS', :name => 'Sevenoaks Bus Station')
      helper.at_the_location(station).should == 'at the Sevenoaks Bus Station'
    end
  
  end
  
  describe 'when returning the readable location type of a location' do 
  
    it 'should return "stop" for a stop' do 
      helper.readable_location_type(Stop.new(:stop_type => 'BCS')).should == 'stop'
    end
    
    it 'should return "stop" for a stop' do 
      helper.readable_location_type(Stop.new(:stop_type => 'BCT')).should == 'stop'
    end
    
    it 'should return "route" for a route' do 
      helper.readable_location_type(Route.new).should == 'route'
    end
    
    it 'should return "bus route" for a bus route' do 
      helper.readable_location_type(BusRoute.new).should == 'bus route'
    end
    
    it 'should return "route" for a metro/tram route' do 
      helper.readable_location_type(TramMetroRoute.new).should == 'route'
    end
    
    it 'should return "stop area" for a stop area' do 
      helper.readable_location_type(StopArea.new(:area_type => 'GBCS')).should == 'bus/coach station'
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
