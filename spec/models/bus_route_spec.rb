require 'spec_helper'

describe BusRoute do
  
  describe 'when finding existing routes' do 
  
    it 'should include in the results returned a route with the same number, mode of transport and stop codes' do 
      atco_codes = ['13001612B'] 
      route = BusRoute.new(:number => '807', 
                           :transport_mode_id => 1)
      atco_codes.each do |atco_code|
        route.route_stops << RouteStop.new(:stop => Stop.new(:atco_code => atco_code))
      end
      BusRoute.find_existing(route).include?(routes(:number_807_bus)).should be_true
    end
    
  end
  
  describe 'name' do 
  
    it 'should be of the form "Bus route 807"' do 
      route = routes(:number_807_bus)
      route.name.should == 'Bus route 807'
    end
  
  end
  
  
end
