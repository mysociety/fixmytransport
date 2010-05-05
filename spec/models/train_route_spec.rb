require 'spec_helper'

describe TrainRoute do
  
  describe 'when finding existing routes' do 
  
    def add_stops_from_list route, atco_codes
      atco_codes.each do |atco_code|
        stop = (Stop.find_by_atco_code(atco_code) or Stop.new(:atco_code => atco_code))
        route.route_stops << RouteStop.new(:stop => stop)
      end
    end
    
    it 'should include in the results returned a route with the same mode of transport whose stops are a subset of the new route' do 
      atco_codes = ['9100VICTRIC', '9100CLPHMJC', '9100ECROYDN', '9100GTWK', '9100NEW', '9100HYWRDSH'] 
      route = TrainRoute.new(:number => '1F54', 
                             :transport_mode_id => 6)
      add_stops_from_list route, atco_codes
      TrainRoute.find_existing(route).include?(routes(:victoria_to_haywards_heath)).should be_true
    end
    
    it 'should include in the results returned a route with the same mode of transport whose stops are a superset of the new route' do
      atco_codes = ['9100VICTRIC', '9100CLPHMJC', '9100ECROYDN', '9100HYWRDSH'] 
      route = TrainRoute.new(:number => '1F58', 
                             :transport_mode_id => 6)
      add_stops_from_list route, atco_codes
      TrainRoute.find_existing(route).include?(routes(:victoria_to_haywards_heath)).should be_true
    end

  end
  
  describe 'when adding a route' do 
  
    it 'should merge a route with the same stops and terminuses' do 
      @route = TrainRoute.new(:transport_mode => transport_modes(:train))
      routes(:victoria_to_haywards_heath).route_stops.each do |route_stop|
        @route.route_stops.build(:stop => route_stop.stop, :terminus => route_stop.terminus)
      end
      TrainRoute.add!(@route)
      @route.id.should be_nil
    end
    
    it 'should merge a route with the same stops and terminuses that visits a stop twice' do 
      @route = TrainRoute.new(:transport_mode => transport_modes(:train))
      routes(:victoria_to_haywards_heath).route_stops.create(:stop => stops(:haywards_heath_station), :terminus => false)
      routes(:victoria_to_haywards_heath).route_stops.each do |route_stop|
        @route.route_stops.build(:stop => route_stop.stop, :terminus => route_stop.terminus)
      end
      TrainRoute.add!(@route)
      @route.id.should be_nil
    end
    
  end
  
  describe 'name' do 
  
    it 'should be of the form "Train route between Haywards Heath and London Victoria"' do 
      route = routes(:victoria_to_haywards_heath)
      route.name.should == 'Train route between Haywards Heath and London Victoria'
    end
    
    describe 'when given a stop to start from' do 
      
      describe 'if the stop is not a terminus' do 
        
        it 'should be of the form "Train between Haywards Heath and London Victoria"' do 
          route = routes(:victoria_to_haywards_heath)
          route.name(stops(:gatwick_airport_station)).should == 'Train between Haywards Heath and London Victoria'
        end
        
      end
      
      describe 'if the stop is a terminus' do 
        
        it 'should be of the form "Train to London Victoria"' do 
          route = routes(:victoria_to_haywards_heath)
          route.name(stops(:haywards_heath_station)).should == 'Train to London Victoria'
        end
        
      end

    end
  
  end
  
end
