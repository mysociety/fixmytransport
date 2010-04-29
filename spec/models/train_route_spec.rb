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
  
  describe 'name' do 
  
    it 'should be of the form "Train route between Haywards Heath and London Victoria"' do 
      route = routes(:victoria_to_haywards_heath)
      route.name.should == 'Train route between Haywards Heath and London Victoria'
    end
  
  end
  
end
